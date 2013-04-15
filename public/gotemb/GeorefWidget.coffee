# Extend `obj` with `mixin`
extend = (obj, mixin) ->
	obj[name] = method for name, method of mixin        
	obj

define [
	"dojo/_base/declare"
	"dijit/_WidgetBase"
	"dijit/_TemplatedMixin"
	"dijit/_WidgetsInTemplateMixin"
	"dojo/text!./GeorefWidget/templates/GeorefWidget.html"
	"dojo/_base/connect"
	"esri/layers/ArcGISImageServiceLayer"
	"esri/request"
	# ---
	"dojox/form/FileInput"
	"dijit/form/Button"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, {connect}, ArcGISImageServiceLayer, request) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "ClassifyWidget"
		map: null # should be bound to a `Map` instance before using the widget
		imageFile: null
		uploadForm: null
		imageServiceUrl: "http://lamborghini.uae.esri.com:6080/arcgis/rest/services/gr_WorldImagery/ImageServer"
		imageServiceLayer: null
		state: {}
		postCreate: ->
			@imageServiceLayer = new ArcGISImageServiceLayer @imageServiceUrl
			connect @imageServiceLayer, "onLoad", =>
				@imageServiceLayer.setOpacity 0
				@map.addLayer @imageServiceLayer
		upload: ->
			if @imageFile.value.length is 0
				return console.error "An image must be selected!"
			@state.rastertype = if @imageFile.value.indexOf("las") is -1 then "Raster Dataset" else "HillshadedLAS"
			console.log "Step 1/3: Uploading"
			esri.request
				url: @imageServiceUrl + "/uploads/upload"
				form: @uploadForm
				content: f: "json"
				handleAs: "text"
				timeout: 600000
				load: (response1, io) =>
					response1 = JSON.stringify response1
					if response1.success
						console.log "Step 2/3: Uploaded, processing the image on server side..."
						esri.request
							url: @imageServiceUrl + "/add"
							content:
								itemIds: response1.item.itemID
								rasterType: @state.rastertype
								minimumCellSizeFactor: 0.1
								maximumCellSizeFactor: 10
								f: "json"
							handleAs: "json"
							timeout: 600000
							load: (response2, io) =>
								#...
							error: (error, io) =>
								console.error error
					else
						console.error "Unsuccessful upload:\n#{response1}"
				error: (error, io) =>
					console.error error