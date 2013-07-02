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
		console.log " - getWIPs"
		callback? [].concat io.sockets.clients().filter((x) -> x isnt socket).map((x) -> x.wip)...

	socket.on "addWIP", (rasterId, callback) ->
		console.log " - addWIP: #{rasterId}"
		if io.sockets.clients().some((x) -> rasterId in x.wip)
			callback? success: false
		else
			socket.wip.push rasterId
			socket.broadcast.emit "addedWIP", rasterId
			callback? success: true

	socket.on "removeWIP", (rasterId, callback) ->
		console.log " - removeWIP: #{rasterId}"
		if rasterId not in socket.wip
			callback? success: false
		else
			socket.wip = socket.wip.filter (x) -> x isnt rasterId
			socket.broadcast.emit "removedWIP", rasterId
			callback? success: true

	socket.on "modifiedRaster", (rasterId, callback) ->
		console.log " - modifiedRaster: #{rasterId}"
		if rasterId not in socket.wip
			callback? success: false
		else
			socket.broadcast.emit "modifiedRaster", rasterId
			callback? success: true

	socket.on "disconnect", ->
		for rasterId in socket.wip
			console.log " - removeWIP: #{rasterId}"
			socket.broadcast.emit "removedWIP", rasterId

server.listen (port = process.env.PORT ? 5080), -> console.log "Listening on port #{port}"