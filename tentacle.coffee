Meshblu = require 'meshblu'
through = require 'through'

meshbluJSON = require './meshblu.json'
TentacleTransformer = require 'tentacle-protocol-buffer'

class Tentacle
  constructor: (tentacleConnection) ->
    @tentacleTransformer =
      new TentacleTransformer()

    @authenticationTransformer =
      new TentacleTransformer message: 'MeshbluAuthentication'

    @tentacleConnection = tentacleConnection

  start: =>
    console.log 'start called'
    @meshbluConn = Meshblu.createConnection meshbluJSON
    @meshbluConn.on 'ready',  @onMeshbluReady
    @meshbluConn.on 'message', @onMeshbluMessage
    @meshbluConn.on 'config', @onMeshbluConfig

    @tentacleConnection.on 'error', @onMicrobluConnectionError
    @tentacleConnection.on 'end', @onMicrobluConnectionClosed
    @tentacleConnection.pipe through(@onMicrobluMessageData)
    @tentacleConnection.pipe through(@onMicrobluAuthenticationData)

  onMeshbluReady: =>
    console.log "I'm ready!"

  onMeshbluMessage: (message) =>
    console.log 'got message'
    @sendMessageToMicroblu topic: 'action', message.payload

  onMeshbluConfig: (config) =>
    console.log 'got message'
    @sendMessageToMicroblu topic: 'config', pins: config.options.pins

  onMicrobluMessageData: (chunk) =>
    return unless @meshbluCredentials?

    console.log 'adding message data'
    @tentacleTransformer.addData chunk
    @sendMessageToMeshblu()

  onMicrobluAuthenticationData: (chunk) =>
    return if @meshbluCredentials?

    console.log 'adding authentication data'
    @authenticationTransformer.addData chunk
    @authenticateWithMeshblu()

  onMicrobluConnectionError: (error) =>
    console.log 'client errored'
    @cleanup()

  onMicrobluConnectionClosed: (data) =>
    console.log 'client closed the connection'
    @cleanup()

  sendMessageToMeshblu: =>
    try
      while (message = @tentacleTransformer.toJSON())
        console.log 'sending message to meshblu'

        @meshbluConn.message( devices: '*',  payload: message )

    catch error
      console.log "I got this error: #{error.message}"
      @cleanup()

  sendMessageToMicroblu: (msg) =>
    console.log 'sending message to microblu'
    console.log JSON.stringify(msg, null, 2)
    @tentacleConnection.write @tentacleTransformer.toProtocolBuffer(msg)

  cleanup: =>
    @tentacleConn.destroy()
    @meshbluConn.close()

module.exports = Tentacle
