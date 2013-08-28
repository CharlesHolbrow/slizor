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

new MidiMsgType 'noteOn',           2,  true,   0x90
new MidiMsgType 'noteOff',          2,  true,   0x80
new MidiMsgType 'pitchBend',        2,  true,   0xE0, true
new MidiMsgType 'cc',               2,  true,   0xB0
new MidiMsgType 'clock',            0,  false,  0xF8
new MidiMsgType 'start',            0,  false,  0xFA
new MidiMsgType 'songPosition',     2,  false,  0xF2, true
new MidiMsgType 'channelPressure',  1,  true,   0xD0

class MidiStreamParser extends events.EventEmitter

  constructor: ->
    @super
    @_midiMsgType = undefined
    @_sysex = false
    @_midi =
      size: undefined
      nibble1: undefined
      nibble2: undefined
      status: undefined
      firstByte: undefined

  _parseStatus: (byte)->
    @_midi.status = byte
    @_midi.nibble1 = byte & 0xF0
    @_midi.nibble2 = byte & 0x0F
    @_midiMsgType = byStatus[@_midi.nibble1]
    @_midiMsgType = byStatus[byte] unless @_midiMsgType
    @_midi.firstByte = undefined
    unless @_midiMsgType
      @emit 'mysteryStatusByte', byte
      return
    if @_midiMsgType.size == 0
      @emit @_midiMsgType.name

  _parseFirst: (byte)->
    unless @_midiMsgType
      @emit 'mysteryDataByte', byte
      return
    if @_midiMsgType.size == 1
      @emit @_midiMsgType.name, byte, @_midi.nibble2 if @_midiMsgType.hasChannel
      @_midi.status = undefined
    else
      # expect another byte
      @_midi.firstByte = byte

  _parseSecond: (byte)->
    if @_midiMsgType.isFourteenBit
      @emit @_midiMsgType.name,
        @_midi.firstByte * 128 + byte,
        @_midi.nibble2 if @_midiMsgType.hasChannel
    else
      @emit @_midiMsgType.name, @_midi.firstByte, byte, @_midi.nibble2
    @_midi.status = undefined
    @_midi.firstByte = undefined

  parseByte: (byte)->
    if byte & 128 then @_parseStatus byte
    else if @_midi.firstByte is undefined then @_parseFirst byte
    else @_parseSecond byte
  parseArray: (input)->
    @parseByte(byte) for byte in input
  parseBytes: ->
    @parseByte(byte) for byte in arguments

module.exports.MidiStreamParser = MidiStreamParser
