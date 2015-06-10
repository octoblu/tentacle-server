net = require 'net'
_ = require 'lodash'
through = require 'through'
Tentacle = require './tentacle'

server = net.createServer (client) =>
  console.log 'client connected.'
  tentacle = new Tentacle(client)
  tentacle.start()

server.listen 8111, =>
  console.log "And we're up."
