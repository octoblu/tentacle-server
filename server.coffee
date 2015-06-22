net = require 'net'
_ = require 'lodash'
through = require 'through'
Tentacle = require './tentacle'

clientCount = 0
server = net.createServer (client) =>
  console.log "#{new Date()}\t client ##{++clientCount} connected."
  tentacle = new Tentacle(client)
  tentacle.start()

server.listen 8111, => console.log "And we're up."
