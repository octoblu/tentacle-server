net = require 'net'
MicrobluTransformer = require 'tentacle-protocol-buffer'
tentacleTranslator = new MicrobluTransformer message: 'MicrobluState', format: 'binary'
server = net.createServer (client) =>
  console.log 'client connected.'
  client.on 'data', (data) =>
    tentacleTranslator.toJSON data, (err, msg)=>
      console.log("msg is: #{JSON.stringify(msg)}")

  client.on 'end', (data) =>
    console.log "end: #{data}"

  client.on 'error', (error) =>
    console.log 'client errored'

server.listen 8111, =>
  console.log "And we're up."
