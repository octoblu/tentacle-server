meshblu = require 'meshblu'
through = require 'through'
debug   = require('debug')('meshblu:tentacle-server')
_ = require 'lodash'

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

    @tentacleConn.on 'error', @onTentacleConnectionError
    @tentacleConn.on 'end', @onTentacleConnectionClosed
    @tentacleConn.pipe through(@onTentacleData)

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
    debug "received message\n#{JSON.stringify(message, null, 2)}"
    return unless message?.payload?

    @messageTentacle _.extend({}, message.payload, topic: 'action')

  onMeshbluConfig: (config) =>
    debug "got config: \n#{JSON.stringify(config, null, 2)}"
    return unless config?.options?

    @messageTentacle topic: 'config', pins: config.options.pins

  onTentacleData: (data) =>
    debug "adding #{data.length} bytes from tentacle"
    @parseTentacleMessage data
    @tentacleTransformer.addData data
    @parseTentacleMessage()

  onTentacleConnectionError: (error) =>
    debug "client errored with message: #{error?.message}"
    @cleanup()

  onTentacleConnectionClosed: (data) =>
    debug 'client closed the connection'
    @cleanup()

  parseTentacleMessage: =>
    try
      while (message = @tentacleTransformer.toJSON())
        debug "I got the message\n#{JSON.stringify(message, null, 2)}"

        @messageMeshblu(message) if message.topic == 'action'
        @authenticateWithMeshblu(message.authentication) if message.topic == 'authentication'

    catch error
      debug "I got this error: #{error.message}"
      @cleanup()

  messageMeshblu: (msg) =>
    debug "Sending message to meshblu:\n#{JSON.stringify(msg, null, 2)}"
    return unless @meshbluConn?
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
        debug "Authentication failed with error: #{error.message}"
        @cleanup()

  messageTentacle: (msg) =>
    debug "Sending message to the tentacle: #{JSON.stringify(msg, null, 2)}"
    @tentacleConn.write @tentacleTransformer.toProtocolBuffer(msg)

  cleanup: =>
    @tentacleConn.destroy() if @tentacleConn?
    @meshbluConn.close() if @meshbluConn?

module.exports = Tentacle
