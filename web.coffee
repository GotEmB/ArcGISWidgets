express = require "express"
http = require "http"
socket_io = require "socket.io"

expressServer = express()
expressServer.configure ->

	expressServer.use express.bodyParser()
	expressServer.use (req, res, next) ->
		req.url = "/page.html" if req.url is "/"
		next()
	expressServer.use express.static "#{__dirname}/public", maxAge: 31557600000, (err) -> console.log "Static: #{err}"
	expressServer.use expressServer.router

server = http.createServer expressServer

io = socket_io.listen server
io.set "log level", 0
io.sockets.on "connection", (socket) ->
	socket.wip = []

	socket.on "getWIPs", (callback) ->
		callback? [].concat io.sockets.clients().filter((x) -> x isnt socket).map((x) -> x.wip)...

	socket.on "addWIP", (rasterId, callback) ->
		if io.sockets.clients().some((x) -> rasterId in x.wip)
			callback? success: false
		else
			socket.wip.push rasterId
			socket.broadcast.emit "addedWIP", rasterId
			callback? success: true

	socket.on "removeWIP", (rasterId) ->
		if rasterId not in socket.wip
			callback? success: false
		else
			socket.wip = socket.wip.filter (x) -> x isnt rasterId
			socket.broadcast.emit "removedWIP", rasterId
			callback? success: true

server.listen (port = process.env.PORT ? 5080), -> console.log "Listening on port #{port}"