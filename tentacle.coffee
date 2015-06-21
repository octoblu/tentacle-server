meshblu = require 'meshblu'
through = require 'through'
debug   = require('debug')('meshblu:tentacle-server')

TentacleTransformer = require 'tentacle-protocol-buffer'

class Tentacle
  constructor: (tentacleConn) ->
    @tentacleTransformer =
      new TentacleTransformer()

    @authenticationTransformer =
      new TentacleTransformer message: 'MeshbluAuthentication'

    @tentacleConn = tentacleConn

  start: =>
    debug 'start called'

    @tentacleConn.on 'error', @onMicrobluConnectionError
    @tentacleConn.on 'end', @onMicrobluConnectionClosed
    @tentacleConn.pipe through(@onMicrobluData)

  listenToMeshbluMessages: =>
    return if @alreadyListening

    @meshbluConn.on 'ready',  @onMeshbluReady
    @meshbluConn.on 'message', @onMeshbluMessage
    @meshbluConn.on 'config', @onMeshbluConfig

    @alreadyListening = true

  onMeshbluReady: =>
    debug "I'm ready!"
    @meshbluConn.whoami {}, @onMeshbluConfig

  onMeshbluMessage: (message) =>
    debug 'got message'
    @sendMessageToMicroblu topic: 'action', message.payload

  onMeshbluConfig: (config) =>
    debug "got config: \n#{JSON.stringify(config, null, true)}"
    @sendMessageToMicroblu topic: 'config', pins: config?.options?.pins

  onMicrobluData: (data) =>
    debug "adding #{data.length} bytes from microblu"
    @parseMicrobluMessage data
    @tentacleTransformer.addData data
    @parseMicrobluMessage()

  onMicrobluConnectionError: (error) =>
    debug 'client errored'
    @cleanup()

  onMicrobluConnectionClosed: (data) =>
    debug 'client closed the connection'
    @cleanup()

  parseMicrobluMessage: =>
    try
      while (message = @tentacleTransformer.toJSON())
        debug "I got the message"
        debug JSON.stringify(message, null, 2)
        @messageMeshblu(message) if message.topic == 'action'
        @authenticateWithMeshblu(message.authentication) if message.topic == 'authentication'

    catch error
      debug "I got this error: #{error.message}"
      @cleanup()

  messageMeshblu: (msg) =>
    debug "I'm supposed to be sending a message to meshblu"
    return unless @meshbluConn?
    debug "I have a connection, so I'm sending it"
    @meshbluConn.message '*', payload: msg

  authenticateWithMeshblu: (credentials) =>
      try
        debug "authenticating with credentials: #{JSON.stringify(credentials)}"
        @meshbluConn = meshblu.createConnection(
          "uuid":  credentials.uuid,
          "token": credentials.token
        )

        @listenToMeshbluMessages()
      catch error
        debug "I got this error: #{error.message}"
        @cleanup()

  sendMessageToMicroblu: (msg) =>
    debug 'sending message to microblu'
    debug JSON.stringify(msg, null, 2)
    @tentacleConn.write @tentacleTransformer.toProtocolBuffer(msg)

  cleanup: =>
    @tentacleConn.destroy() if @tentacleConn?
    @meshbluConn.close() if @meshbluConn?

module.exports = Tentacle
