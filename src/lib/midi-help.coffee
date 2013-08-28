module.exports =
  noteOn: (note, velocity = 127, channel = 0)->
    [0x90 + channel, note, velocity]
  noteOff: (note, velocity = 0, channel = 0)->
    [0x80 + channel, note, velocity]
  cc: (number, value, channel = 0)->
    [0xB0 + channel, number, value]
  pitchBend: (value = 8192, channel = 0)->
    # min     = 0
    # max     = 16383
    # center  = 8192, 0x2000
    [0xE0 + channel, value % 128, Math.floor(value / 128)]

