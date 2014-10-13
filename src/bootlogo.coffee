domReady = Q.promise (resolve) ->
  handler = resolve.bind(null, document)
  document.addEventListener 'DOMContentLoaded', handler, no
  window.addEventListener 'load', handler, no

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
  location.hash = '#toc' unless document.querySelector("#{location.hash}.section")
  (new vidius.Assets)
  .loadText('shaders/sprite-renderer.glsl')
  .loadImage('assets/arrow.png')
  .loadImage('assets/cursor.png')
  .loadImage('assets/electric.png')
  .loadImage('assets/font.png')
  .loadImage('assets/overlay.png')
  .loadImage('assets/vidius.png')
  .loadSample('assets/bang.wav')
  .loadSample('assets/beep.wav')
  .loadSample('assets/donk.wav')
  .wait()
).then((assets) ->
  vidius.DisplayList::shaderSource = assets.sprite_renderer_glsl
  displayList = new vidius.DisplayList(document.getElementById('display'), 256, 192, 256, assets.overlay_png)

  font = new vidius.BitmapFont(assets.font_png)

  logo1  = displayList.createSprite(assets.vidius_png  ).move(80, -32)
  logo2  = displayList.createSprite(assets.electric_png).move(80, 104)
  arrow  = displayList.createSprite(assets.arrow_png   ).move(80, 176)
  cursor = displayList.createSprite(assets.cursor_png  ).move( 0,   0)

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

    assets.bang_wav.play()

    # document.querySelector('#navigation').classList.add 'highlight'

    activeSection = null
    sections = {}

    for element in document.querySelectorAll('.section')
      sections[element.id] =
        id:element.id
        element:element
        sprites:for link, i in element.querySelectorAll('.navigation a') then do (link) ->
          image = font.textToImage(link.textContent)
          x = (256 - image.width) / 2
          y = 120 + i * font.height

          link.addEventListener 'mouseenter', (->
            cursor.move x - 16, y
            displayList.add cursor
            assets.beep_wav.currentTime = 0
            assets.beep_wav.play()
          ), no

          link.addEventListener 'mouseleave', (->
            displayList.remove cursor
          ), no

          displayList.createSprite(image).move(x, y)

    showSection = (id) ->
      displayList.remove cursor
      displayList.remove sprite for sprite in activeSection.sprites if activeSection?
      if (activeSection = sections[id])?
        displayList.add sprite for sprite in activeSection.sprites
      return

    window.onhashchange = ->
      assets.donk_wav.currentTime = 0
      assets.donk_wav.play()
      showSection location.hash.slice(1)

    showSection location.hash.slice(1)
  ).start()
  displayList.start()
).done()
