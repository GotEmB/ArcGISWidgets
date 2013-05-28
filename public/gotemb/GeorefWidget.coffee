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
	"esri/tasks/GeometryService"
	# ---
	"dojox/form/FileInput"
	"dijit/form/Button"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, {connect}, ArcGISImageServiceLayer, request, MosaicRule, Polygon, GeometryService) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "ClassifyWidget"
		map: null # should be bound to a `Map` instance before using the widget
		imageFile: null
		uploadForm: null
		imageServiceUrl: "http://lamborghini.uae.esri.com:6080/arcgis/rest/services/amberg_gcs_1/ImageServer"
		imageServiceLayer: null
		referenceLayerUrl: "http://lamborghini.uae.esri.com:6080/arcgis/rest/services/amberg_gcs_reference/ImageServer"
		referenceLayer: null
		geometryServiceUrl: "http://lamborghini:6080/arcgis/rest/services/Utilities/Geometry/GeometryServer"
		geometryService: null
		rastertype: null
		imageIDs: []
		currentId: null
		postCreate: ->
			@imageServiceLayer = new ArcGISImageServiceLayer @imageServiceUrl
			@geometryService = new GeometryService @geometryServiceUrl
			connect @imageServiceLayer, "onLoad", =>
				@map.addLayer @referenceLayer = new ArcGISImageServiceLayer @referenceLayerUrl
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
								@currentId = id
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
		roughTransform: ->
			return console.error "An image must be uploaded in step 1." unless @currentId?
			request
				url: @imageServiceUrl + "/#{@currentId}/info"
				content: f: "json"
				handleAs: "json"
				load: (response1) =>
					src = response1.extent
					request
						url: @imageServiceUrl + "/update"
						content:
							f: "json"
							rasterId: @currentId
							geodataTransforms: JSON.stringify [
								geodataTransform: "Polynomial"
								geodataTransformArguments:
									sourcePoints: [
										{x: src.xmin, y: src.ymin}
										{x: src.xmin, y: src.ymax}
										{x: src.xmax, y: src.ymin}
									]
									targetPoints: do =>
										aspectRatio = (src.xmax - src.xmin) / (src.ymax - src.ymin)
										map =
											width: @map.extent.getWidth()
											height: @map.extent.getHeight()
											center: @map.extent.getCenter().toJson()
										dest =
											width: Math.min map.width, map.height * aspectRatio
											height: Math.min map.height, map.width / aspectRatio
										dest.xmin = map.center.x - dest.width / 2
										dest.xmax = map.center.x + dest.width / 2
										dest.ymin = map.center.y - dest.height / 2
										dest.ymax = map.center.y + dest.height / 2
										[
											{x: dest.xmin, y: dest.ymin}
											{x: dest.xmin, y: dest.ymax}
											{x: dest.xmax, y: dest.ymin}
										]
									polynomialOrder: 1
									spatialReference: src.spatialReference
							]
						handleAs: "json"
						load: =>
							request
								url: @imageServiceUrl + "/query"
								content:
									objectIds: @currentId
									returnGeometry: true
									outFields: ""
									f: "json"
								handleAs: "json"
								load: (response3) =>
									@map.setExtent new Polygon(response3.features[0].geometry).getExtent().expand 2
								error: console.error
						error: console.error
						(usePost: true)
				error: console.error
				(usePost: true)
		computeAndTransform: ->
			return console.error "An image must be uploaded in step 1." unless @currentId?
			request
				url: @imageServiceUrl + "/#{@currentId}/info"
				content: f: "json"
				handleAs: "json"
				load: (response1) =>
					src = response1.extent
					request
						url: @imageServiceUrl + "/computeTiePoints"
						content:
							f: "json"
							rasterId: @currentId
							geodataTransforms: JSON.stringify [
								geodataTransform: "Identity"
								geodataTransformArguments:
									spatialReference: src.spatialReference
							]
						handleAs: "json"
						load: (response2) =>
							# ...
							long i = 234;
						error: console.error
						(usePost: true)
				error: console.error
				(usePost: true)