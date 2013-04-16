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
	"esri/layers/MosaicRule"
	"esri/geometry/Polygon"
	# ---
	"dojox/form/FileInput"
	"dijit/form/Button"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, {connect}, ArcGISImageServiceLayer, request, MosaicRule, Polygon) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "ClassifyWidget"
		map: null # should be bound to a `Map` instance before using the widget
		imageFile: null
		uploadForm: null
		imageServiceUrl: "http://lamborghini.uae.esri.com:6080/arcgis/rest/services/gr_WorldImagery/ImageServer"
		imageServiceLayer: null
		rastertype: null
		imageIDs: []
		postCreate: ->
			@imageServiceLayer = new ArcGISImageServiceLayer @imageServiceUrl
			connect @imageServiceLayer, "onLoad", =>
				@imageServiceLayer.setOpacity 0
				@map.addLayer @imageServiceLayer
		upload: ->
			return console.error "An image must be selected!" if @imageFile.value.length is 0
			@rastertype = if @imageFile.value.indexOf("las") is -1 then "Raster Dataset" else "HillshadedLAS"
			console.info "Step 1/3: Uploading..."
			request
				url: @imageServiceUrl + "/uploads/upload"
				form: @uploadForm
				content: f: "json"
				handleAs: "json"
				timeout: 600000
				load: (response1) =>
					return console.error "Unsuccessful upload:\n#{response1}" unless response1.success
					console.info "Step 2/3: Uploaded, processing the image on server side..."
					request
						url: @imageServiceUrl + "/add"
						content:
							itemIds: response1.item.itemID
							rasterType: @rastertype
							minimumCellSizeFactor: 0.1
							maximumCellSizeFactor: 10
							f: "json"
						handleAs: "json"
						load: (response2) =>
							if id = response2.addResults[0].rasterId
								console.info "Step 3/3: Navigate to the image."
								@imageIDs.push id.toString()
								if @imageIDs.length > 0
									@imageServiceLayer.setMosaicRule extend(
										new MosaicRule
										method: MosaicRule.METHOD_LOCKRASTER
										lockRasterIds: @imageIDs
									), true
								request
									url: @imageServiceUrl + "/query"
									content:
										objectIds: id
										returnGeometry: true
										outFields: ""
										f: "json"
									handleAs: "json"
									load: (response3) =>
										@map.setExtent new Polygon(response3.features[0].geometry).getExtent().expand 2
										@imageServiceLayer.setOpacity 1
										console.info "Succeeded!"
									error: console.error
						error: console.error
						(usePost: true)
				error: console.error