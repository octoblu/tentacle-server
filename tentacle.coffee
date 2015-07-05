Meshblu = require 'meshblu'
through = require 'through'
debug   = require('debug')('meshblu:tentacle-server')
_ = require 'lodash'

TentacleTransformer = require 'tentacle-protocol-buffer'

class Tentacle
  constructor: (tentacleConn, options={}) ->
    @meshbluHost      = options.meshbluHost
    @meshbluPort      = options.meshbluPort
    @meshbluProtocol  = options.meshbluProtocol
    @messageSchema = options.messageSchema || require './message-schema.json'
    @optionsSchema = options.optionsSchema || require './options-schema.json'

    @tentacleTransformer = new TentacleTransformer()
    @tentacleConn = tentacleConn

  start: =>
    debug 'start called'

    @tentacleConn.on 'error', @onTentacleConnectionError
    @tentacleConn.on 'end', @onTentacleConnectionClosed
    @tentacleConn.pipe through(@onTentacleData)

  listenToMeshbluMessages: =>
    return if @alreadyListening

    @meshbluConn.on 'error', @onMeshbluError
    @meshbluConn.on 'ready',  @onMeshbluReady
    @meshbluConn.on 'notReady', @onMeshbluNotReady
    @meshbluConn.on 'message', @onMeshbluMessage
    @meshbluConn.on 'config', @onMeshbluConfig
    @meshbluConn.on 'whoami', @onMeshbluConfig

    @alreadyListening = true

  onMeshbluError: (error) =>
    debug 'meshblu errored'
    @cleanup error

  onMeshbluReady: =>
    debug "I'm ready!"
    @meshbluConn.whoami {}, @onMeshbluConfig

  onMeshbluNotReady: =>
    debug "I wasn't ready! Auth failed or meshblu blipped"
    @cleanup()

  onMeshbluMessage: (message) =>
    debug "received message\n#{JSON.stringify(message, null, 2)}"
    return unless message?.payload?

    @messageTentacle _.extend({}, message.payload, topic: 'action')

  onMeshbluConfig: (config) =>
    debug "got config: \n#{JSON.stringify(config, null, 2)}"

    return @addSchemas() unless config?.messageSchema? && config?.optionsSchema
    return unless config?.options?
    tentacleConfig = topic: 'config'
    _.extend tentacleConfig, _.pick( config.options, 'pins', 'broadcastPins', 'broadcastInterval' )

    @messageTentacle tentacleConfig
    @deviceConfigured = true

  addSchemas: =>
    @meshbluConn.update
      uuid: @credentials.uuid
      messageSchema: @messageSchema
      optionsSchema: @optionsSchema

  onTentacleData: (data) =>
    debug "adding #{data.length} bytes from tentacle"
    @parseTentacleMessage data
    @tentacleTransformer.addData data
    @parseTentacleMessage()

  onTentacleConnectionError: (error) =>
    debug 'tentacle connection error'
    @cleanup error

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
      debug "error parsing tentacle message"
      @cleanup error

  messageMeshblu: (msg) =>
    debug "Sending message to meshblu:\n#{JSON.stringify(msg, null, 2)}"
    return debug "device not configured" unless @deviceConfigured
    @meshbluConn.message '*', msg

  authenticateWithMeshblu: (credentials) =>
      @credentials = credentials
      try
        debug "authenticating with credentials: #{JSON.stringify(credentials)}"
        @meshbluConn = Meshblu.createConnection
          uuid    : credentials.uuid
          token   : credentials.token
          server  : @meshbluHost
          port    : @meshbluPort

        @listenToMeshbluMessages()

      catch error
        debug "Authentication failed with error: #{error.message}"
        @cleanup()

  messageTentacle: (msg) =>
    debug "Sending message to the tentacle: #{JSON.stringify(msg, null, 2)}"
    @tentacleConn.write @tentacleTransformer.toProtocolBuffer(msg)

  cleanup: (error) =>
    debug "got an error: #{JSON.stringify(error, null, 2)}" if error?
    @tentacleConn.destroy() if @tentacleConn?
    @meshbluConn.close() if @meshbluConn?

module.exports = Tentacle
