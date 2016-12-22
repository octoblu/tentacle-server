_ = require 'lodash'
debug = require('debug')('meshblu:tentacle-server')

Tentacle = require 'meshblu-tentacle'
Meshblu = require 'meshblu'

MESSAGE_SCHEMA = require 'tentacle-protocol-buffer/message-schema.json'
OPTIONS_SCHEMA = require 'tentacle-protocol-buffer/options-schema.json'

class TentacleServer
  constructor: (meshbluOptions, socket) ->
    @socket = socket
    @meshbluHost      = meshbluOptions.server
    @meshbluPort      = meshbluOptions.port
    @messageSchema = MESSAGE_SCHEMA
    @optionsSchema = OPTIONS_SCHEMA
    @tentacle = new Tentacle socket

  start: =>

    @tentacle.on "message", (message) =>
      debug 'tentacle sent message'
      return unless @meshbluConn?
      @meshbluConn.message _.extend devices: '*', message

    @tentacle.on "request-config", =>
      debug 'tentacle requested config'
      return unless meshbluConn?
      @meshblu.whoami {}, @onMeshbluConfig

    @tentacle.on "authenticate", @authenticateWithMeshblu

    @tentacle.on "error", (error) =>
      debug 'tentacle errored.'
      @close()

    @tentacle.on "close", =>
      debug 'closing tentacle socket'
      @close()

    @tentacle.start()

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
      @close()

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
    @close error

  onMeshbluReady: =>
    debug "I'm ready!"
    @meshbluConn.whoami {}, @onMeshbluConfig

  onMeshbluNotReady: =>
    debug "I wasn't ready! Auth failed or meshblu blipped"
    @close()

  onMeshbluMessage: (message) =>
    debug "received message\n#{JSON.stringify(message, null, 2)}"
    @tentacle.onMessage message

  onMeshbluConfig: (config) =>
    debug "got config: \n#{JSON.stringify(config, null, 2)}"
    return @addSchemas() if @needToUpdateSchemas config
    return unless config?.options?

    @tentacle.onConfig config.options
    @deviceConfigured = true

  needToUpdateSchemas: (device) =>
    return true unless device?.messageSchema? && device?.optionsSchema && device?.options
    false

  addSchemas: =>
    return unless @meshbluConn?

    @meshbluConn.update
      uuid: @credentials.uuid
      messageSchema: @messageSchema
      optionsSchema: @optionsSchema
      options: pins: []

  close: =>
    debug "closing connections"
    @socket.close() if @socket?.close?
    @socket.end() if @socket?.end?
    @meshbluConn.close(->) if @meshbluConn?

    @tentacle = null
    @meshbluConn = null
    @socket = null

module.exports = TentacleServer
