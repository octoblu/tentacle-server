
_ = require 'lodash'
Tentacle = require './tentacle'
{SerialPort} = require 'serialport'
debug = require('debug')('meshblu:tentacle-server')

MESHBLU_HOST          = process.env.MESHBLU_HOST || 'meshblu.octoblu.com'
MESHBLU_PORT          = process.env.MESHBLU_PORT || '443'
MESHBLU_PROTOCOL      = process.env.MESHBLU_PROTOCOL || 'https'


serial = new SerialPort "/dev/tty.usbmodem1411", baudrate: 57600

tentacle = new Tentacle( serial,
  meshbluHost:     MESHBLU_HOST
  meshbluPort:     MESHBLU_PORT
  meshbluProtocol: MESHBLU_PROTOCOL
)

tentacle.start()
