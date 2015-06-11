Meshblu = require 'meshblu'
through = require 'through'

meshbluJSON = require './meshblu.json'
TentacleTransformer = require 'tentacle-protocol-buffer'

class Tentacle
  constructor: (socket) ->
    @tentacleTransformer = new TentacleTransformer()
    @socket = socket

  start: =>
    @meshbluConn = Meshblu.createConnection meshbluJSON

    @meshbluConn.on 'ready', => console.log "I'm ready!"

    @meshbluConn.on('config', (msg) =>
      @configureDevice msg.options, (error, response) =>
        return @handleError(error) if error?

    @meshbluConn.on 'message', (msg) =>
      @messageDevice msg.payload, (error, response) =>
        return @handleError(error) if error?

    @socket.pipe through( (chunk) =>
        console.log 'adding data'
        @tentacleTransformer.addData chunk

        @getDeviceMessage (error, msg) =>
          console.log 'sending message to meshblu'
          return @handleError(error) if error?
          @messageMeshblu msg
    ))

    @socket.on 'end', (data) => @meshbluConn.close()

  getDeviceMessage: (callback) =>
      try
        while (msg = @tentacleTransformer.toJSON())
          callback null, msg.pins

      catch error
        callback error

  messageMeshblu: (msg)=>
    @meshbluConn.message devices: '*',  payload: msg

  configureDevice: (config) =>
    console.log 'config'
    console.log JSON.stringify(config, null, 2)
    @socket.write @tentacleTransformer.toProtocolBuffer( topic: 'config', pins: config.pins )

  messageDevice: (msg) =>
    @socket.write @tentacleTransformer.toProtocolBuffer topic: 'message', pins: msg

  handleError: (error) =>
    @socket.end()

module.exports = Tentacle
