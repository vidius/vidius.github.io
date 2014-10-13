vidius = (window.vidius ?= {})

class vidius.BitmapFont
  constructor: (@image) ->
    @width = @image.width / 16
    @height = @image.height / 16

  textWidth: (text) ->
    text.length * @width

  drawCharCode: (context, code, x, y) ->
    sx = @width * (code & 0x0F)
    sy = @height * (code >> 4)
    context.drawImage @image, sx, sy, @width, @height, x, y, @width, @height
    return

  drawText: (context, text, x, y) ->
    for i in [0...text.length]
      @drawCharCode(context, text.charCodeAt(i), x, y)
      x += @width
    return

  textToImage: (text) ->
    canvas = document.createElement('canvas')
    canvas.width = @textWidth(text)
    canvas.height = @height

    context = canvas.getContext('2d')
    @drawText context, text, 0, 0

    canvas

class vidius.TexturePacker
  class Node
    constructor: (@left, @top, @width, @height) ->

    add: (image) ->
      {width, height} = image
      if @image?
        null # occupied
      else if @a? and @b?
        @a.add(image) ? @b.add(image)
      else if width is @width and height is @height
        @image = image
        this
      else if width <= @width and height <= @height
        dw = @width - width
        dh = @height - height

        if dw > dh
          @a = new Node(@left, @top, width, @height)
          @b = new Node(@left + width, @top, dw, @height)
        else
          @a = new Node(@left, @top, @width, height)
          @b = new Node(@left, @top + height, @width, dh)

        @a.add image
      else
        null

    each: (func) ->
      if @image?
        func @image, @left, @top, @width, @height
      else if @a? and @b?
        @a.each func
        @b.each func
      return

    draw: (context) ->
      if @image?
        context.clearRect @left, @top, @width, @height
        context.drawImage @image, @left, @top
      else if @a? and @b?
        @a.draw context
        @b.draw context
      return

  constructor: (@textureSize) ->
    @root = new Node(0, 0, @textureSize, @textureSize)
    @textureList = []

    @texture = document.createElement('canvas')
    @texture.width = @textureSize
    @texture.height = @textureSize

    @context = @texture.getContext('2d')

  add: (image) ->
    node = @root.add(image)
    if node?
      @textureList.push image
      node.draw @context

      new Sprite(node.left, node.top, node.width, node.height)
    else
      throw new Error("failed to allocate texture space")

  # grow: ->
  #   @textureSize *= 2
  #   @node = new Node(0, 0, @textureSize, @textureSize)
  #   @atlas.width = @textureSize
  #   @atlas.height = @textureSize
  #   @add(texture) for texture in @textureList.splice(0)
  #   this

  each: (func) ->
    @root.each func

class vidius.Sprite
  constructor: (u, v, w, h) ->
    @pos = x:0, y:0
    @size = x:w, y:h
    @uv = x:u, y:v
    @priority = 1

  move: (x, y) ->
    @pos.x = x
    @pos.y = y
    this

  setPriority: (@priority) -> this

  test: (x, y) ->
    x >= @x and x < @x + @width and
    y >= @y and y < @y + @height

class vidius.DisplayList
  constructor: (@canvas, virtualWidth, virtualHeight, textureSize, overlay) ->
    @texturePacker = new TexturePacker(textureSize)
    @sprites = []

    displayList = this
    glsl = Glsl
      canvas:@canvas
      fragment:@shaderSource
      variables:
        time:0
        atlas:@texturePacker.texture
        atlasAspect:{x:textureSize, y:textureSize}
        displayAspect:{x:virtualWidth, y:virtualHeight}
        overlay:overlay
        sprites:@sprites
        spritesLength:@sprites.length
      init:-> displayList.glsl = this
      update:@__update

  createSprite: (image, add = yes) ->
    sprite = @texturePacker.add(image)
    @atlasNeedsUpdate = yes
    sprite

  # destroySprite: (sprite) ->
  #   @remove sprite
  #   @texturePacker.remove sprite
  #   @atlasNeedsUpdate = yes
  #   return

  add: (sprite) ->
    if @sprites.indexOf(sprite) is -1
      @sprites.push sprite
      @sprites.sort (a, b) -> b.priority - a.priority
    this

  remove: (sprite) ->
    @sprites.splice(i, 1) if (i = @sprites.indexOf(sprite)) isnt -1
    this

  clear: ->
    @sprites.splice(0)

  start: ->
    @glsl.start()

  stop: ->
    @glsl.stop()

  __update: (time, dt) =>
    if @atlasNeedsUpdate
      atlasSize = @texturePacker.textureSize
      @glsl.sync 'atlas'
      @glsl.set 'atlasAspect', x:atlasSize, y:atlasSize
      atlasNeedsUpdate = no
    @glsl.sync 'sprites'
    @glsl.set 'spritesLength', @sprites.length
    @glsl.set 'time', time
    TWEEN.update time
