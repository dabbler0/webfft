WINDOW_SIZE = 4200

# Compat
navigator.getUserMedia = navigator.getUserMedia ? navigator.webkitGetUserMedia ? navigator.mozGetUserMedia ? navigator.msGetUserMedia

getWindow = (i, windowSize) -> (1 - ((i - windowSize) / windowSize) ** 2) ** 1.25

color = '#000'

renderFFT = (spectrum, ctx) ->
  ctx.clearRect 0, 0, 500, 500
  ctx.strokeStyle = color

  ctx.beginPath()
  ctx.moveTo 0, 500
  for data, i in spectrum
    ctx.lineTo i * 500 / spectrum.length, 500 - data * 2
  
  ctx.stroke()

###
# Proscutes experiment (FAILED)

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

    # Take a 2048-point approximation of squared distance
    for i in [lower + 1...upper] by ((upper - lower) / 2048)
      ssd += (other.get(i) - @get(i)) ** 2

    ssd = Math.sqrt ssd / 2048

    return ssd
###

cosineSimilarity = (a, b) -> # and B are Uint8Arrays
  dotProduct = 0

  for el, i in a
    dotProduct += el * b[i]
  
  magA = 0
  for el in a then magA += el ** 2
  magA = Math.sqrt magA

  magB = 0
  for el in b then magB += el ** 2
  magB = Math.sqrt magB

  if magA is 0 or magB is 0 then return 0

  return dotProduct / (magA * magB)
  ###

  a = new ProscutesFunction a; a.proscutesTranslate(); a.proscutesScale()
  b = new ProscutesFunction b; b.proscutesTranslate(); b.proscutesScale()

  return a.distanceTo b
  ###


canvas = document.getElementById 'main'
ctx = canvas.getContext '2d'

analyser = null

navigator.getUserMedia audio: true, ((stream) ->
  AudioContext = window.AudioContext ? window.webkitAudioContext
  context = new AudioContext()

  audioInput = context.createMediaStreamSource stream

  volume = context.createGain()
  audioInput.connect volume

  analyser = context.createAnalyser()
  analyser.fftSize = 2048
  #analyser.smoothingTimeConstant = 0.3
  volume.connect analyser

  voider = context.createGain()
  voider.gain.value = 0

  analyser.connect voider

  voider.connect context.destination

  update()

), ((error) ->
  console.log 'ERROR', error
)

redOut = document.getElementById 'red_val'
redAvgOut = document.getElementById 'red_avg'

blueOut = document.getElementById 'blue_val'
blueAvgOut = document.getElementById 'blue_avg'

asample = new Float64Array 2048
bsample = new Float64Array 2048

averageASampleSimilarity = 0
averageBSampleSimilarity = 0

recordingA = recordingB = false

update = ->
  data = new Uint8Array analyser.frequencyBinCount

  analyser.getByteFrequencyData data

  renderFFT data, ctx
  
  if recordingA
    asample[i] += el for el, i in data
  else if recordingB
    bsample[i] += el for el, i in data
  else
    redOut.innerText = aSimilarity = - Math.log 1 - cosineSimilarity(data, asample)
    redAvgOut.innerText = averageASampleSimilarity

    blueOut.innerText = bSimilarity = - Math.log 1 - cosineSimilarity(data, bsample)
    blueAvgOut.innerText = averageBSampleSimilarity

    if aSimilarity - averageASampleSimilarity > 0.5 and aSimilarity > bSimilarity
      color = '#F00'

    if bSimilarity - averageBSampleSimilarity > 0.5 and bSimilarity > aSimilarity
      color = '#00F'

    averageASampleSimilarity = 0.99 * averageASampleSimilarity + 0.01 * aSimilarity
    averageBSampleSimilarity = 0.99 * averageBSampleSimilarity + 0.01 * bSimilarity

  setTimeout update, 20

document.getElementById('step1start').addEventListener 'click', ->
  document.getElementById('step1stop').className = 'btn btn-danger'
  @className = 'btn btn-primary disabled'
  recordingA = true

document.getElementById('step1stop').addEventListener 'click', ->
  document.getElementById('step1start').className = 'btn btn-primary'
  @className = 'btn btn-danger disabled'
  recordingA = false

document.getElementById('step2start').addEventListener 'click', ->
  document.getElementById('step2stop').className = 'btn btn-danger'
  @className = 'btn btn-primary disabled'
  recordingB = true

document.getElementById('step2stop').addEventListener 'click', ->
  document.getElementById('step2start').className = 'btn btn-primary'
  @className = 'btn btn-danger disabled'
  recordingB = false
