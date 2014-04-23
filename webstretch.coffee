WINDOW_SIZE = 4200

# Compat
navigator.getUserMedia = navigator.getUserMedia ? navigator.webkitGetUserMedia ? navigator.mozGetUserMedia ? navigator.msGetUserMedia

getWindow = (i, windowSize) -> (1 - ((i - windowSize) / windowSize) ** 2) ** 1.25

renderFFT = (spectrum, ctx) ->
  ctx.clearRect 0, 0, 500, 500
  spectrum = spectrum.magnitude()
  ctx.strokeStyle = '#00F'

  ctx.beginPath()
  ctx.moveTo 0, 500
  for data, i in spectrum
    ctx.lineTo 2 * i * 500 / spectrum.length, 500 - 100 * data
  
  ctx.stroke()

canvas = document.getElementById 'main'
ctx = canvas.getContext '2d'

navigator.getUserMedia audio: true, ((stream) ->
  AudioContext = window.AudioContext ? window.webkitAudioContext
  context = new AudioContext()

  volume = context.createGain()

  audioInput = context.createMediaStreamSource stream

  audioInput.connect volume

  BUFFER_SIZE = 512
  recorder = context.createJavaScriptNode BUFFER_SIZE, 2, 2
  
  inputBuffer = new Float32Array WINDOW_SIZE
  inputBufferStartPosition = 0

  for i in [0...WINDOW_SIZE] then inputBuffer[i] = 0

  outputBuffer = new Float32Array WINDOW_SIZE
  outputBufferStartPosition = 0

  for i in [0...WINDOW_SIZE] then outputBuffer[i] = 0

  trueOutput = []

  recorder.onaudioprocess = (event) ->
    if trueOutput.length < 48000 * 2
      realData = event.inputBuffer.getChannelData 0

      for el in realData
        inputBuffer[inputBufferStartPosition] = el
        inputBufferStartPosition = (inputBufferStartPosition + 1) % WINDOW_SIZE

      # Populate fft input buffer
      complexData = new complex_array.ComplexArray WINDOW_SIZE
      
      complexData.map (value, i, n) ->
        value.real = inputBuffer[(inputBufferStartPosition + i) % WINDOW_SIZE] * getWindow i, WINDOW_SIZE
      
      # FFT
      fft = complexData.FFT()
      
      # Randomize phases
      fft.map (value, i, n) ->
        mag = Math.sqrt value.real ** 2 + value.imag ** 2
        ang = 2 * Math.PI * Math.random()
        value.real = mag * Math.cos ang
        value.imag = mag * Math.sin ang
      
      renderFFT fft, ctx

      # IFFT
      ifft = fft.InvFFT()
      
      ifft.map (value, i, n) ->
        outputBuffer[(outputBufferStartPosition + i) % WINDOW_SIZE] += value.real * getWindow i, WINDOW_SIZE
      
      # Advance output
      for [0...BUFFER_SIZE]
        trueOutput.push outputBuffer[outputBufferStartPosition]
        outputBuffer[outputBufferStartPosition] = 0
        outputBufferStartPosition = (outputBufferStartPosition + 1) % WINDOW_SIZE

  window.playTrueOutput = ->
    ###
    floats = new Float32Array trueOutput.length
    for sample, i in trueOutput
      floats[i] = sample
    ###
    
    buffer = context.createBuffer 1, trueOutput.length, context.sampleRate / 2
    source = context.createBufferSource()

    buffer.getChannelData(0).set trueOutput

    source.buffer = buffer
    source.connect context.destination
    source.start 0

  console.log 'sample rate:', context.sampleRate

  volume.connect recorder
  recorder.connect context.destination
), ((error) ->
  console.log 'ERROR', error
)
