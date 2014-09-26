domReady = Q.promise (resolve) ->
  handler = resolve.bind(null, document)
  document.addEventListener 'DOMContentLoaded', handler, no
  window.addEventListener 'load', handler, no

basename = (path) ->
  /([^/]+)$/.exec(path)?[1] ? path

loadImage = (obj, src) ->
  Q.promise((resolve, reject) ->
    image = new Image
    image.addEventListener 'load', (-> resolve image), no
    image.addEventListener 'error', ((error) -> reject error), no
    image.src = src
  ).then (image) ->
    obj[basename src] = image

loadSample = (obj, src) ->
  Q.promise((resolve, reject) ->
    sample = new Audio
    sample.addEventListener 'canplay', (-> resolve sample), no
    sample.addEventListener 'error', ((error) -> reject error), no
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
  canvas = document.getElementById('display')
  context = canvas.getContext('2d')

  displayList = new gfx.DisplayList(context)
  displayList.scale = 3

  overlay = assets['overlay.png']
  bang = assets['bang.wav']
  beep = assets['beep.wav']
  donk = assets['donk.wav']

  font = new gfx.BitmapFont(assets['font.png'])

  arrow  = new gfx.Sprite(assets['arrow.png'],    80, 176, 2)
  cursor = new gfx.Sprite(assets['cursor.png'],    0,   0, 1)
  logo1  = new gfx.Sprite(assets['vidius.png'],   80, -32, 1)
  logo2  = new gfx.Sprite(assets['electric.png'], 80, 104, 1)

  new TWEEN.Tween(logo1)
  .to({y:80}, 2000)
  .onStart(-> displayList.add logo1)
  .onComplete(->
    displayList.add logo2

    setTimeout (->
      new TWEEN.Tween(arrow)
      .to({y:arrow.y - 16}, 500)
      .easing(TWEEN.Easing.Quadratic.InOut)
      .repeat(5)
      .yoyo(yes)
      .onStart(-> displayList.add arrow)
      .onComplete(-> displayList.remove arrow)
      .start()
    ), 500

    bang.play()

    document.querySelector('#navigation').classList.add 'highlight'

    for link, i in document.querySelectorAll('#navigation a') then do (link) ->
      image = font.textToImage(link.textContent)
      x = (256 - image.width) / 2
      y = 120 + i * font.height

      sprite = new gfx.Sprite(image, x, y, 2)
      displayList.add sprite

      link.addEventListener 'mouseenter', (->
        cursor.x = x - 16
        cursor.y = y
        displayList.add cursor
        donk.pause()

        beep.currentTime = 0
        beep.play()
      ), no

      link.addEventListener 'mouseleave', (->
        displayList.remove cursor
        donk.currentTime = 0
        donk.play()
      ), no
  ).start()

  tick = (time) ->
    requestAnimationFrame tick, canvas
    TWEEN.update time

    context.clearRect 0, 0, canvas.width, canvas.height

    context.globalCompositeOperation = 'source-over'
    displayList.draw()

    context.globalCompositeOperation = 'multiply'
    context.drawImage overlay, 0, 0

  requestAnimationFrame tick, canvas
).done()
