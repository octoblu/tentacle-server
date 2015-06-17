meshblu = require 'meshblu'
through = require 'through'

TentacleTransformer = require 'tentacle-protocol-buffer'

class Tentacle
  constructor: (tentacleConn) ->
    @tentacleTransformer =
      new TentacleTransformer()

    @authenticationTransformer =
      new TentacleTransformer message: 'MeshbluAuthentication'

    @tentacleConn = tentacleConn

  start: =>
    console.log 'start called'

    @tentacleConn.on 'error', @onMicrobluConnectionError
    @tentacleConn.on 'end', @onMicrobluConnectionClosed
    @tentacleConn.pipe through(@onMicrobluData)

  listenToMeshbluMessages: =>
    @meshbluConn.on 'ready',  @onMeshbluReady
    @meshbluConn.on 'message', @onMeshbluMessage
    @meshbluConn.on 'config', @onMeshbluConfig

  onMeshbluReady: =>
    console.log "I'm ready!"

  onMeshbluMessage: (message) =>
    console.log 'got message'
    @sendMessageToMicroblu topic: 'action', message.payload

  onMeshbluConfig: (config) =>
    console.log 'got message'
    @sendMessageToMicroblu topic: 'config', pins: config.options.pins

  onMicrobluData: (data) =>
    console.log "adding #{data.length} bytes from microblu"
    @parseMicrobluMessage data
    @tentacleTransformer.addData data
    @parseMicrobluMessage()

  onMicrobluConnectionError: (error) =>
    console.log 'client errored'
    @cleanup()

  onMicrobluConnectionClosed: (data) =>
    console.log 'client closed the connection'
    @cleanup()

  parseMicrobluMessage: =>
    try
      while (message = @tentacleTransformer.toJSON())
        console.log "I got the message"
        console.log JSON.stringify(message, null, 2)
        @messageMeshblu(message) if message.topic == 'action'
        @authenticateWithMeshblu(message.authentication) if message.topic == 'authentication'

    catch error
      console.log "I got this error: #{error.message}"
      @cleanup()

  messageMeshblu: (msg) =>
    console.log "I'm supposed to be sending a message to meshblu"
    return unless @meshbluConn?
    console.log "I have a connection, so I'm sending it"
    @meshbluConn.message '*', payload: msg

  authenticateWithMeshblu: (credentials)=>
      try
        console.log "authenticating with credentials: #{JSON.stringify(credentials)}"
        @meshbluConn = meshblu.createConnection(
          "uuid":  credentials.uuid,
          "token": credentials.token
        )

        @listenToMeshbluMessages()
      catch error
        console.log "I got this error: #{error.message}"
        @cleanup()

  sendMessageToMicroblu: (msg) =>
    console.log 'sending message to microblu'
    console.log JSON.stringify(msg, null, 2)
    @tentacleConn.write @tentacleTransformer.toProtocolBuffer(msg)

  cleanup: =>
    @tentacleConn.destroy() if @tentacleConn?
    @meshbluConn.close() if @meshbluConn?

module.exports = Tentacle
