define [
	"dojo/request"
], (request) ->
	getClasses: (filePath, callback) ->
		request.get(filePath, headers: "X-Requested-With": "").then (gsg) ->
			lines = gsg.match /^((?!#|\/\*).)+/gm
			nLayers = Number lines[0].match(/\d+/g)[3]
			callback? do ->
				for line in lines[1..] by nLayers + 2
					cells = line.match /[^ ]+/g
					value: Number cells[0]
					classname: cells[2]