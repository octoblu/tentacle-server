Meshblu = require 'meshblu'
through = require 'through'

meshbluJSON = require './meshblu.json'
TentacleTransformer = require 'tentacle-protocol-buffer'

class Tentacle
  constructor: (tentacleConnection) ->
    @tentacleTransformer = new TentacleTransformer()
    @tentacleConnection = tentacleConnection

  start: =>
    console.log 'start called'
    @meshbluConn = Meshblu.createConnection meshbluJSON
    @meshbluConn.on 'ready',  @onMeshbluReady
    @meshbluConn.on 'message', @onMeshbluMessage

    @tentacleConnection.on 'error', @onMicrobluConnectionError
    @tentacleConnection.on 'end', @onMicrobluConnectionClosed
    @tentacleConnection.pipe through(@onMicrobluData)

  onMeshbluReady: =>
    console.log "I'm ready!"

  onMeshbluMessage: (message) =>
    @sendMessageToMicroblu message.payload

  onMicrobluData: (chunk) =>
    console.log 'adding data'
    @addData chunk
    @sendMessageToMeshblu()

  addData: (data) =>
    @tentacleTransformer.addData data

  onMicrobluConnectionError: (error) =>
    console.log 'client errored'

  onMicrobluConnectionClosed: (data) =>
    @meshbluConn.close()

  sendMessageToMeshblu: =>
    try
      while (message = @tentacleTransformer.toJSON())
        console.log 'sending message to meshblu'
        @meshbluConn.message( devices: '*',  payload: message )

    catch error
      console.log "I got this error: #{error.message}"
      @tentacleConnection.end()

  sendMessageToMicroblu: (msg) =>
    @tentacleConnection.write @tentacleTransformer.toProtocolBuffer(msg)


module.exports = Tentacle
