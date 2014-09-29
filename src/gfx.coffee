class BitmapFont
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

class Sprite
  constructor: (@image, @x, @y, @priority = 0) ->
    @width = @image.width ? 0
    @height = @image.height ? 0

  test: (x, y) ->
    x >= @x and x < @x + @width and
    y >= @y and y < @y + @height

class DisplayList
  byPriority = (a, b) -> a.priority - b.priority

  constructor: (@context) ->
    @sprites = []
    @scale = 1

    # @context.imageSmoothingEnabled = no
    # @context.webkitImageSmoothingEnabled = no
    # @context.mozImageSmoothingEnabled = no

  add: (sprite) ->
    @sprites.push(sprite) if @sprites.indexOf(sprite) is -1
    @sprites.sort byPriority
    this

  remove: (sprite) ->
    @sprites.splice(i, 1) if (i = @sprites.indexOf(sprite)) isnt -1
    this

  clear: ->
    @sprites.splice(0)
    this

  query: (x, y) ->
    for sprite in @sprites when sprite.test(x, y)
      return sprite
    null

  draw: ->
    @context.save()
    @context.setTransform 1, 0, 0, 1, 0, 0
    @context.scale @scale, @scale

    for {image, x, y} in @sprites
      @context.drawImage image, 0|x, 0|y

    @context.restore()
    return

window.gfx = {BitmapFont, DisplayList, Sprite}
