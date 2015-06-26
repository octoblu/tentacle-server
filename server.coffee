net = require 'net'
_ = require 'lodash'
through = require 'through'
Tentacle = require './tentacle'
debug = require('debug')('meshblu:tentacle-server')

TENTACLE_SERVER_PORT  = process.env.TENTACLE_SERVER_PORT || 80
MESHBLU_HOST          = process.env.MESHBLU_HOST || 'meshblu.octoblu.com'
MESHBLU_PORT          = process.env.MESHBLU_PORT || '443'
MESHBLU_PROTOCOL      = process.env.MESHBLU_PROTOCOL || 'https'

server = net.createServer (client) =>
  tentacle = new Tentacle( client,
    meshbluHost:     MESHBLU_HOST
    meshbluPort:     MESHBLU_PORT
    meshbluProtocol: MESHBLU_PROTOCOL
  )

  tentacle.start()

server.listen TENTACLE_SERVER_PORT, => debug "And we're up. Port: #{TENTACLE_SERVER_PORT}"
