Meshblu = require 'meshblu'
through = require 'through'

meshbluJSON = require './meshblu.json'
TentacleTransformer = require 'tentacle-protocol-buffer'

class Tentacle
  constructor: (socket) ->
    @tentacleTransformer = new TentacleTransformer()
    @socket = socket

  addData: (data) =>
    @tentacleTransformer.addData data

  start: =>
    @meshbluConn = Meshblu.createConnection meshbluJSON
    @meshbluConn.on 'ready', => console.log "I'm ready!"
    @meshbluConn.on 'message', (msg) =>
      @sendMessageToMicroblu msg.payload

    @socket.pipe(through( (chunk) =>
      console.log 'adding data'
      @addData chunk
      @sendMessageToMeshblu()
    )).on 'data', (data) =>
      console.log "data: #{data}"

    @socket.on 'end', (data) =>
      @meshbluConn.close()

    @socket.on 'error', (error) =>
      console.log 'client errored'

  sendMessageToMeshblu: =>
    try
      while (message = @tentacleTransformer.toJSON())
        console.log 'sending message to meshblu'
        @meshbluConn.message( devices: '*',  payload: message )

    catch error
      console.log "I got this error: #{error.message}"
      @socket.end()

  sendMessageToMicroblu: (msg) =>
    @socket.write(@tentacleTransformer.toProtocolBuffer(msg))


module.exports = Tentacle
