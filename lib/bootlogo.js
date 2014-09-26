// Generated by CoffeeScript 2.0.0-beta8
void function () {
  var basename, debounce, domReady, loadImage, loadSample;
  domReady = Q.promise(function (resolve) {
    var handler;
    handler = resolve.bind(null, document);
    document.addEventListener('DOMContentLoaded', handler, false);
    return window.addEventListener('load', handler, false);
  });
  basename = function (path) {
    var cache$, cache$1;
    cache$ = null != (cache$1 = /([^/]+)$/.exec(path)) ? cache$1[1] : void 0;
    return null != cache$ ? cache$ : path;
  };
  loadImage = function (obj, src) {
    return Q.promise(function (resolve, reject) {
      var image;
      image = new Image;
      image.addEventListener('load', function () {
        return resolve(image);
      }, false);
      image.addEventListener('error', function (error) {
        return reject(error);
      }, false);
      return image.src = src;
    }).then(function (image) {
      return obj[basename(src)] = image;
    });
  };
  loadSample = function (obj, src) {
    return Q.promise(function (resolve, reject) {
      var sample;
      sample = new Audio;
      sample.addEventListener('canplay', function () {
        return resolve(sample);
      }, false);
      sample.addEventListener('error', function (error) {
        return reject(error);
      }, false);
      sample.src = src;
      return sample.load();
    }).then(function (sample) {
      return obj[basename(src)] = sample;
    });
  };
  debounce = function (ms, func) {
    var callback, savedArgs, savedContext, timeout;
    timeout = null;
    savedContext = null;
    savedArgs = null;
    callback = function () {
      return func.apply(savedContext, savedArgs);
    };
    return function (args) {
      args = 1 <= arguments.length ? [].slice.call(arguments, 0) : [];
      if (null != timeout)
        clearTimeout(timeout);
      savedContext = this;
      savedArgs = args;
      timeout = setTimeout(callback, ms);
    };
  };
  domReady.then(function () {
    var assets;
    assets = {};
    return Q.all([
      loadImage(assets, 'assets/arrow.png'),
      loadImage(assets, 'assets/cursor.png'),
      loadImage(assets, 'assets/electric.png'),
      loadImage(assets, 'assets/font.png'),
      loadImage(assets, 'assets/overlay.png'),
      loadImage(assets, 'assets/vidius.png'),
      loadSample(assets, 'assets/bang.wav'),
      loadSample(assets, 'assets/beep.wav'),
      loadSample(assets, 'assets/donk.wav')
    ]).thenResolve(assets);
  }).then(function (assets) {
    var arrow, bang, beep, canvas, context, cursor, displayList, donk, font, logo1, logo2, overlay, tick;
    canvas = document.getElementById('display');
    context = canvas.getContext('2d');
    displayList = new gfx.DisplayList(context);
    displayList.scale = 3;
    overlay = assets['overlay.png'];
    bang = assets['bang.wav'];
    beep = assets['beep.wav'];
    donk = assets['donk.wav'];
    font = new gfx.BitmapFont(assets['font.png']);
    arrow = new gfx.Sprite(assets['arrow.png'], 80, 176, 2);
    cursor = new gfx.Sprite(assets['cursor.png'], 0, 0, 1);
    logo1 = new gfx.Sprite(assets['vidius.png'], 80, -32, 1);
    logo2 = new gfx.Sprite(assets['electric.png'], 80, 104, 1);
    new TWEEN.Tween(logo1).to({ y: 80 }, 2e3).onStart(function () {
      return displayList.add(logo1);
    }).onComplete(function () {
      var i, link;
      displayList.add(logo2);
      setTimeout(function () {
        return new TWEEN.Tween(arrow).to({ y: arrow.y - 16 }, 500).easing(TWEEN.Easing.Quadratic.InOut).repeat(5).yoyo(true).onStart(function () {
          return displayList.add(arrow);
        }).onComplete(function () {
          return displayList.remove(arrow);
        }).start();
      }, 500);
      bang.play();
      document.querySelector('#navigation').classList.add('highlight');
      return function (accum$) {
        for (var cache$ = document.querySelectorAll('#navigation a'), i$ = 0, length$ = cache$.length; i$ < length$; ++i$) {
          link = cache$[i$];
          i = i$;
          accum$.push(function (link) {
            var image, sprite, x, y;
            image = font.textToImage(link.textContent);
            x = (256 - image.width) / 2;
            y = 120 + i * font.height;
            sprite = new gfx.Sprite(image, x, y, 2);
            displayList.add(sprite);
            link.addEventListener('mouseenter', function () {
              cursor.x = x - 16;
              cursor.y = y;
              displayList.add(cursor);
              donk.pause();
              beep.currentTime = 0;
              return beep.play();
            }, false);
            return link.addEventListener('mouseleave', function () {
              displayList.remove(cursor);
              donk.currentTime = 0;
              return donk.play();
            }, false);
          }(link));
        }
        return accum$;
      }.call(this, []);
    }).start();
    tick = function (time) {
      requestAnimationFrame(tick, canvas);
      TWEEN.update(time);
      context.clearRect(0, 0, canvas.width, canvas.height);
      context.globalCompositeOperation = 'source-over';
      displayList.draw();
      context.globalCompositeOperation = 'multiply';
      return context.drawImage(overlay, 0, 0);
    };
    return requestAnimationFrame(tick, canvas);
  }).done();
}.call(this);

//# sourceMappingURL=bootlogo.map