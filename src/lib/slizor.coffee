###

slizor
https://github.com/charlesholbrow/slizor

Copyright (c) 2013 Charles Holbrow
Licensed under the MIT license.

###

midi  = require('midi')
help  = require('midi-help')

noteOn    = help.noteOn
noteOff   = help.noteOff
cc        = help.cc
pitchBend = help.pitchBend

output  = new midi.output
console.log 'Opening midi port:', output.getPortName(0)
output.openPort(0)

monode  = require('monode')()

values = [60, 8192, 60, 60]

monode.on 'device', (device)->
  return unless device.isArc
  device.on 'enc', (n, delta)->
    if n == 0
      output.sendMessage noteOff(values[n])
      output.sendMessage noteOn(values[n] += delta)
    else if n == 1
      output.sendMessage pitchBend(values[n] += delta)

  device.on 'key', (n, s)->
    output.sendMessage cc(123, 0)# all notes off
