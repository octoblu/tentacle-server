net = require 'net'
_ = require 'lodash'
through = require 'through'

TentacleTransformer = require 'tentacle-protocol-buffer'

server = net.createServer (client) =>
  console.log 'client connected.'
  tentacleTransformer = new TentacleTransformer()

  client.pipe(through((chunk) =>
    tentacleTransformer.addData(chunk)
    try
      while (decoded = tentacleTransformer.toJSON())
        console.log 'while looping with decoded = ', JSON.stringify(decoded,null,2)
        msg = topic: 'config', pins: [ { number: 5, value: 4 } ]

        console.log "bytes written before: #{client.bytesWritten}"
        client.write( tentacleTransformer.toProtocolBuffer(msg) )
        client.write '\0'

        console.log "bytes written after: #{client.bytesWritten}"

    catch error
      console.log "I got this error: #{error.message}"
      client.end()
  )).on 'data', (data) =>
    console.log "data: #{data}"

  client.on 'end', (data) =>
    console.log "end: #{data}"

  client.on 'error', (error) =>
    console.log 'client errored'

server.listen 8111, =>
  console.log "And we're up."
