net = require 'net'
debug = require('debug')('meshblu:tentacle-server')
TentacleServer = require './tentacle-server'

TENTACLE_SERVER_PORT  = process.env.TENTACLE_SERVER_PORT || 80
MESHBLU_HOST          = process.env.MESHBLU_HOST || 'meshblu.octoblu.com'
MESHBLU_PORT          = process.env.MESHBLU_PORT || '443'

meshbluOptions = server: MESHBLU_HOST, port: MESHBLU_PORT
server = net.createServer (socket) =>
  try
    tentacleServer = new TentacleServer(meshbluOptions, socket)
    tentacleServer.start()

  catch error
    debug "TentacleServer crashed with error: #{error?.message}"
    tentacleServer = null

server.listen TENTACLE_SERVER_PORT, => debug "And we're up. Port: #{TENTACLE_SERVER_PORT}"
