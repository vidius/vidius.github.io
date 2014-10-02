domReady = Q.promise (resolve) ->
  handler = resolve.bind(null, document)
  document.addEventListener 'DOMContentLoaded', handler, no
  window.addEventListener 'load', handler, no

basename = (path) ->
  /([^/]+)$/.exec(path)?[1] ? path

loadText = (obj, src) ->
  Q.promise((resolve, reject) ->
    xhr = new XMLHttpRequest
    xhr.addEventListener 'load', (-> resolve xhr.responseText), no
    xhr.addEventListener 'error', reject, no
    xhr.open 'GET', src
    xhr.send()
  ).then (text) ->
    obj[basename src] = text

loadImage = (obj, src) ->
  Q.promise((resolve, reject) ->
    image = new Image
    image.addEventListener 'load', (-> resolve image), no
    image.addEventListener 'error', reject, no
    image.src = src
  ).then (image) ->
    obj[basename src] = image

loadSample = (obj, src) ->
  Q.promise((resolve, reject) ->
    sample = new Audio
    sample.addEventListener 'canplay', (-> resolve sample), no
    sample.addEventListener 'error', reject, no
    sample.src = src
    sample.load()
  ).then (sample) ->
    obj[basename src] = sample

debounce = (ms, func) ->
  timeout = null
  savedContext = null
  savedArgs = null

  callback = -> func.apply(savedContext, savedArgs)

  (args...) ->
    clearTimeout(timeout) if timeout?
    savedContext = this
    savedArgs = args
    timeout = setTimeout(callback, ms)
    return

domReady.then(->
  assets = {}
  Q.all([
    loadText(assets, 'shaders/sprite-renderer.glsl')
    loadImage(assets, 'assets/arrow.png')
    loadImage(assets, 'assets/cursor.png')
    loadImage(assets, 'assets/electric.png')
    loadImage(assets, 'assets/font.png')
    loadImage(assets, 'assets/overlay.png')
    loadImage(assets, 'assets/vidius.png')
    loadSample(assets, 'assets/bang.wav')
    loadSample(assets, 'assets/beep.wav')
    loadSample(assets, 'assets/donk.wav')
  ]).thenResolve(assets)
).then((assets) ->
  DisplayList::shaderSource = assets['sprite-renderer.glsl']
  displayList = new gfx.DisplayList(document.getElementById('display'), 256, 192, 128, assets['overlay.png'])

  font = new gfx.BitmapFont(assets['font.png'])

  packer = new gfx.TexturePacker(128)
  logo1  = displayList.createSprite(assets['vidius.png']  ).move(80, -32)
  logo2  = displayList.createSprite(assets['electric.png']).move(80, 104)
  arrow  = displayList.createSprite(assets['arrow.png']   ).move(80, 176)
  cursor = displayList.createSprite(assets['cursor.png']  ).move( 0,   0)

  debugView = document.querySelector('#debug')
  debugView.appendChild displayList.texturePacker.texture
  debugView.appendChild font.image

  document.addEventListener 'keydown', ((event) ->
    if event.keyCode is 192
      if debugView.style.display is 'block'
        debugView.style.display = 'none'
      else
        debugView.style.display = 'block'
  ), no

  new TWEEN.Tween(logo1.pos)
  .to({y:80}, 2000)
  .onStart(-> displayList.add logo1)
  .onComplete(->
    displayList.add logo2

    setTimeout (->
      new TWEEN.Tween(arrow.pos)
      .to({y:arrow.pos.y - 16}, 500)
      .easing(TWEEN.Easing.Quadratic.InOut)
      .repeat(5)
      .yoyo(yes)
      .onStart(-> displayList.add arrow)
      .onComplete(-> displayList.remove arrow)
      .start()
    ), 500

    assets['bang.wav'].play()

    document.querySelector('#navigation').classList.add 'highlight'

    for link, i in document.querySelectorAll('#navigation a') then do (link) ->
      image = font.textToImage(link.textContent)
      x = (256 - image.width) / 2
      y = 120 + i * font.height

      sprite = displayList.createSprite(image).move(x, y)
      displayList.add sprite

      link.addEventListener 'mouseenter', (->
        cursor.move x - 16, y
        displayList.add cursor

        assets['donk.wav'].pause()

        assets['beep.wav'].currentTime = 0
        assets['beep.wav'].play()
      ), no

      link.addEventListener 'mouseleave', (->
        displayList.remove cursor

        assets['beep.wav'].pause()

        assets['donk.wav'].currentTime = 0
        assets['donk.wav'].play()
      ), no
  ).start()
  displayList.start()
).done()
