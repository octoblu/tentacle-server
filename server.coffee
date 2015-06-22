net = require 'net'
_ = require 'lodash'
through = require 'through'
Tentacle = require './tentacle'
debug = require('debug')('meshblu:tentacle-server')

port        = process.env.TENTACLE_SERVER_PORT ? 8111
meshbluHost = process.env.MESHBLU_HOST
meshbluPort =   process.env.MESHBLU_PORT

server = net.createServer (client) =>
  tentacle = new Tentacle client, meshbluHost: meshbluHost, meshbluPort: meshbluPort
  tentacle.start()

server.listen port, => debug "And we're up. Port: #{port}"
