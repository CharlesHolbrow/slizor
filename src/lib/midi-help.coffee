events = require 'events'

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


byStatus = []
byName = {}
class MidiMsgType
  constructor: (@name, @size, @hasChannel, @status, @isFourteenBit = false)->
    byStatus[status] = @
    byName[name] = @

new MidiMsgType 'noteOn',     2,  true,   0x90
new MidiMsgType 'noteOff',    2,  true,   0x80
new MidiMsgType 'pitchBend',  2,  true,   0xE0, true
new MidiMsgType 'cc',         2,  true,   0xB0
new MidiMsgType 'clock',      0,  false,  0xF8

class MidiStreamParser extends events.EventEmitter
  constructor: ->
    @super
    @_midiMsgType = undefined
    @_midi =
      size: undefined
      nibble1: undefined
      nibble2: undefined
      status: undefined
      firstByte: undefined
  parseStatus: (byte)->
    @_midi.status = byte
    @_midi.nibble1 = byte & 0xF0
    @_midi.nibble2 = byte & 0x0F

    @_midiMsgType = byStatus[@_midi.nibble1]
    @_midiMsgType = byStatus[byte] unless @_midiMsgType

    if @_midiMsgType.size == 0
      @emit @_midiMsgType.name
      @_midi.firstByte = undefined

  parseFirst: (byte)->
    if @_midiMsgType.size == 1
      @emit @_midiMsgType.name, byte
      @_midi.status = undefined
    else
      # expect another byte
      @_midi.firstByte = byte

  parseSecond: (byte)->
    @_midi.secondByte = byte
    @emit @_midiMsgType.name, @_midi.firstByte, byte, @_midi.nibble2
    @_midi.firstByte = undefined

  accept: (byte)->
    if byte & 128 then @parseStatus byte
    else if @_midi.firstByte is undefined then @parseFirst byte
    else @parseSecond byte

module.exports.MidiStreamParser = MidiStreamParser
