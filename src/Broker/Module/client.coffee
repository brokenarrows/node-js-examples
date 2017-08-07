client = (queue, data) ->
  'use strict'
  request = require('request')
  http = require('http')
  querystring = require('querystring')
  server = http.createServer((request, resource) ->
    body = ''
    request.on 'data', (chunk) ->
      body += chunk
      if body.length > 1e5
        request.connection.destroy()
      return
    request.on 'end', ->
      resource.writeHead 200, 'Content-Type': 'application/json'
      result =
        status: 'ok'
        content: querystring.parse(body)
        port: server.address().port
      resource.end JSON.stringify(result) + '\n'
      if typeof data == 'function'
        data result
      return
    return
  ).listen(->
    request.post 'http://localhost' + server.address().port + '/queues/' + queue + '/consumers', {
      form:
        callback_url: 'http://localhost' + server.address().port
    }, (error, resource, body) ->
      if error
        console.warn 'Failed URL request...'
      return
    return
  )
  return

module.exports = client