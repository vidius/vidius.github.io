vidius = (window.vidius ?= {})

basename = (path) ->
  /([^/]+)$/.exec(path)?[1] ? path

slugify = (str) ->
  str.replace(/[^a-z0-9_]+/g, '_')

class vidius.Assets
  constructor: ->
    @promises = {}

  wait: ->
    Q.all(promise for src, promise of @promises).thenResolve(this)

  loadText: (src) ->
    @promises[src] ?=
    Q.promise((resolve, reject) =>
      xhr = new XMLHttpRequest
      xhr.addEventListener 'load', (-> resolve xhr.responseText), no
      xhr.addEventListener 'error', reject, no
      xhr.open 'GET', src
      xhr.send()
    ).then((text) => @[slugify basename src] = text)
    this

  loadImage: (src) ->
    @promises[src] ?=
    Q.promise((resolve, reject) =>
      image = new Image
      image.addEventListener 'load', (-> resolve image), no
      image.addEventListener 'error', reject, no
      image.src = src
    ).then((image) => @[slugify basename src] = image)
    this

  loadSample: (src) ->
    @promises[src] ?=
    Q.promise((resolve, reject) =>
      sample = new Audio
      sample.addEventListener 'canplay', (-> resolve sample), no
      sample.addEventListener 'error', reject, no
      sample.src = src
      sample.load()
    ).then((sample) => @[slugify basename src] = sample)
    this
