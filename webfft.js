(function() {
  var WINDOW_SIZE, analyser, asample, averageASampleSimilarity, averageBSampleSimilarity, blueAvgOut, blueOut, bsample, canvas, color, cosineSimilarity, ctx, getWindow, recordingA, recordingB, redAvgOut, redOut, renderFFT, update, _ref, _ref1, _ref2;

  WINDOW_SIZE = 4200;

  navigator.getUserMedia = (_ref = (_ref1 = (_ref2 = navigator.getUserMedia) != null ? _ref2 : navigator.webkitGetUserMedia) != null ? _ref1 : navigator.mozGetUserMedia) != null ? _ref : navigator.msGetUserMedia;

  getWindow = function(i, windowSize) {
    return Math.pow(1 - Math.pow((i - windowSize) / windowSize, 2), 1.25);
  };

  color = '#000';

  renderFFT = function(spectrum, ctx) {
    var data, i, _i, _len;
    ctx.clearRect(0, 0, 500, 500);
    ctx.strokeStyle = color;
    ctx.beginPath();
    ctx.moveTo(0, 500);
    for (i = _i = 0, _len = spectrum.length; _i < _len; i = ++_i) {
      data = spectrum[i];
      ctx.lineTo(i * 500 / spectrum.length, 500 - data * 2);
    }
    return ctx.stroke();
  };


  /*
   * Proscutes experiment (FAILED)
  
  class ProscutesFunction
    constructor: (@arr) ->
      @scale = [1, 1]
      @translate = [0, 0]
  
    proscutesTranslate: ->
      centroid = [0, 0]
      for val, i in @arr
        centroid[0] += i
        centroid[1] += val
  
      @translate[0] = - centroid[0] / @arr.length
      @translate[1] = - centroid[1] / @arr.length
  
    proscutesScale: ->
      rmsd = [0, 0]
      for val, i in @arr
        rmsd[0] += (i + @translate[0]) ** 2
        rmsd[1] += (val + @translate[1]) ** 2
  
      rmsd[0] = Math.sqrt rmsd[0] / @arr.length
      rmsd[1] = Math.sqrt rmsd[1] / @arr.length
  
      @scale[0] = 1 / rmsd[0]
      @scale[1] = 1 / rmsd[1]
  
    getBounds: -> [@translate[0] * @scale[0], (@translate[0] + @arr.length) * @scale[0]]
  
    get: (x) ->
      return (@arr[Math.floor(x / @scale[0] - @translate[0])] + @translate[1]) * @scale[1]
  
    distanceTo: (other) ->
      ourBounds = @getBounds()
      otherBounds = other.getBounds()
  
      lower = Math.min ourBounds[0], otherBounds[0]
      upper = Math.max ourBounds[1], otherBounds[1]
  
      ssd = 0
  
       * Take a 2048-point approximation of squared distance
      for i in [lower + 1...upper] by ((upper - lower) / 2048)
        ssd += (other.get(i) - @get(i)) ** 2
  
      ssd = Math.sqrt ssd / 2048
  
      return ssd
   */

  cosineSimilarity = function(a, b) {
    var dotProduct, el, i, magA, magB, _i, _j, _k, _len, _len1, _len2;
    dotProduct = 0;
    for (i = _i = 0, _len = a.length; _i < _len; i = ++_i) {
      el = a[i];
      dotProduct += el * b[i];
    }
    magA = 0;
    for (_j = 0, _len1 = a.length; _j < _len1; _j++) {
      el = a[_j];
      magA += Math.pow(el, 2);
    }
    magA = Math.sqrt(magA);
    magB = 0;
    for (_k = 0, _len2 = b.length; _k < _len2; _k++) {
      el = b[_k];
      magB += Math.pow(el, 2);
    }
    magB = Math.sqrt(magB);
    if (magA === 0 || magB === 0) {
      return 0;
    }
    return dotProduct / (magA * magB);

    /*
    
    a = new ProscutesFunction a; a.proscutesTranslate(); a.proscutesScale()
    b = new ProscutesFunction b; b.proscutesTranslate(); b.proscutesScale()
    
    return a.distanceTo b
     */
  };

  canvas = document.getElementById('main');

  ctx = canvas.getContext('2d');

  analyser = null;

  navigator.getUserMedia({
    audio: true
  }, (function(stream) {
    var AudioContext, audioInput, context, voider, volume, _ref3;
    AudioContext = (_ref3 = window.AudioContext) != null ? _ref3 : window.webkitAudioContext;
    context = new AudioContext();
    audioInput = context.createMediaStreamSource(stream);
    volume = context.createGain();
    audioInput.connect(volume);
    analyser = context.createAnalyser();
    analyser.fftSize = 2048;
    volume.connect(analyser);
    voider = context.createGain();
    voider.gain.value = 0;
    analyser.connect(voider);
    voider.connect(context.destination);
    return update();
  }), (function(error) {
    return console.log('ERROR', error);
  }));

  redOut = document.getElementById('red_val');

  redAvgOut = document.getElementById('red_avg');

  blueOut = document.getElementById('blue_val');

  blueAvgOut = document.getElementById('blue_avg');

  asample = new Float64Array(2048);

  bsample = new Float64Array(2048);

  averageASampleSimilarity = 0;

  averageBSampleSimilarity = 0;

  recordingA = recordingB = false;

  update = function() {
    var aSimilarity, bSimilarity, data, el, i, _i, _j, _len, _len1;
    data = new Uint8Array(analyser.frequencyBinCount);
    analyser.getByteFrequencyData(data);
    renderFFT(data, ctx);
    if (recordingA) {
      for (i = _i = 0, _len = data.length; _i < _len; i = ++_i) {
        el = data[i];
        asample[i] += el;
      }
    } else if (recordingB) {
      for (i = _j = 0, _len1 = data.length; _j < _len1; i = ++_j) {
        el = data[i];
        bsample[i] += el;
      }
    } else {
      redOut.innerText = aSimilarity = -Math.log(1 - cosineSimilarity(data, asample));
      redAvgOut.innerText = averageASampleSimilarity;
      blueOut.innerText = bSimilarity = -Math.log(1 - cosineSimilarity(data, bsample));
      blueAvgOut.innerText = averageBSampleSimilarity;
      if (aSimilarity - averageASampleSimilarity > 0.5 && aSimilarity > bSimilarity) {
        color = '#F00';
      }
      if (bSimilarity - averageBSampleSimilarity > 0.5 && bSimilarity > aSimilarity) {
        color = '#00F';
      }
      averageASampleSimilarity = 0.99 * averageASampleSimilarity + 0.01 * aSimilarity;
      averageBSampleSimilarity = 0.99 * averageBSampleSimilarity + 0.01 * bSimilarity;
    }
    return setTimeout(update, 20);
  };

  document.getElementById('step1start').addEventListener('click', function() {
    document.getElementById('step1stop').className = 'btn btn-danger';
    this.className = 'btn btn-primary disabled';
    return recordingA = true;
  });

  document.getElementById('step1stop').addEventListener('click', function() {
    document.getElementById('step1start').className = 'btn btn-primary';
    this.className = 'btn btn-danger disabled';
    return recordingA = false;
  });

  document.getElementById('step2start').addEventListener('click', function() {
    document.getElementById('step2stop').className = 'btn btn-danger';
    this.className = 'btn btn-primary disabled';
    return recordingB = true;
  });

  document.getElementById('step2stop').addEventListener('click', function() {
    document.getElementById('step2start').className = 'btn btn-primary';
    this.className = 'btn btn-danger disabled';
    return recordingB = false;
  });

}).call(this);

//# sourceMappingURL=webfft.js.map
