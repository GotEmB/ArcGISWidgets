###
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
###

# Extend `obj` with `mixin`
extend = (obj, mixin) ->
 	obj[name] = method for name, method of mixin        
 	obj

# Get index of largest
indexOfMax = (arr) ->
	max = -Infinity
	idx = -1
	for a, i in arr
		if a > max
			max = a
			idx = i
	idx

define [
	"dojo/_base/declare"
	"dijit/_WidgetBase"
	"dijit/_TemplatedMixin"
	"dijit/_WidgetsInTemplateMixin"
	"dojo/text!./ClassifyWidget/templates/ClassifyWidget.html"
	"dojo/_base/connect"
	"dijit/Dialog"
	"gotemb/ClassifyWidget/SignatureClassRow"
	"gotemb/ClassifyWidget/signatureFileParser"
	"dojox/color"
	"esri/geometry/Polygon"
	"esri/layers/ArcGISImageServiceLayer"
	"esri/layers/RasterFunction"
	"esri/layers/ImageServiceParameters"
	"esri/tasks/GeometryService"
	"esri/tasks/ProjectParameters"
	"esri/tasks/AreasAndLengthsParameters"
	"esri/layers/FeatureLayer"
	"esri/tasks/query"
	"dojo/request"
	"dijit/form/TextBox"
	"dijit/form/Button"
	"dijit/form/CheckBox"
	"gotemb/ClassifyWidget/Grid"
	"dijit/form/DropDownButton"
	"dijit/TooltipDialog"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, {connect}, Dialog, SignatureClassRow, signatureFileParser, color, Polygon, ArcGISImageServiceLayer, RasterFunction, ImageServiceParameters, GeometryService, ProjectParameters, AreasAndLengthsParameters, FeatureLayer, Query, request) ->
	# Show an error box and log it to console
	showError = (content) ->
		errBox = new Dialog title: "Error", content: content
		errBox.startup()
		errBox.show()
		console.error new Error content
		errBox
	# Convert an `Extent` to an `Polygon`
	extentToPolygon = (extent) ->
		polygon = new Polygon extent.spatialReference
		polygon.addRing [
			[extent.xmin, extent.ymin]
			[extent.xmin, extent.ymax]
			[extent.xmax, extent.ymax]
			[extent.xmax, extent.ymin]
			[extent.xmin, extent.ymin]
		]
		polygon
	# The 'Classify Widget' class
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "ClassifyWidget"
		map: null # should be bound to a `Map` instance before using the widget
		# Widget Inputs
		imageServiceUrlInput: null
		geometryServiceUrlInput: null
		imageServiceLayer: null
		classificationEnabledInput: null
		clipToSignaturePolygonsInput: null
		# SignaturesBox Related
		signaturesBox: null
		signaturesUrlInput: null
		signaturesGrid: null
		customizeClassesButton: null
		# Contains the widget's current state
		state: {}
		constructor: ->
			# Bind the @refresh function to the Map's onExtentChange event
			@watch "map", (attr, oldMap, newMap) =>
				connect newMap, "onExtentChange", @refresh.bind @
		postCreate: ->
			# Setup Signatures dGrid
			@signaturesGrid.set "columns",
				class:
					label: "Signature Class"
					renderCell: (object, value, node) ->
						node.style.verticalAlign = "middle"
						node.textContent = object.get "sigClass"
				color:
					label: "Color"
					renderCell: (object) -> object.domNode
			# UI Chain-reaction
			@classificationEnabledInput.watch "checked", (attr, oldValue, newValue) =>
				@clipToSignaturePolygonsInput.set "disabled", not newValue
			@clipToSignaturePolygonsInput.watch "disabled", (attr, oldValue, newValue) =>
				@clipToSignaturePolygonsInput.set "checked", false if newValue is true
		# Sets the ImageServiceLayer with the url stored in the State
		setImageLayer: (options, callback) ->
			return showError "ImageServiceLayer: Service URL Required." if @state.imageServiceUrl in ["", null, undefined]
			@map.removeLayer @imageServiceLayer if @imageServiceLayer?
			@imageServiceLayer = new ArcGISImageServiceLayer @state.imageServiceUrl, options
			connect @imageServiceLayer, "onLoad", =>
				@map.addLayer @imageServiceLayer
				callback?()
			connect @imageServiceLayer, "onError", (error) =>
				showError "ImageServiceLayer: #{error.message}"
				delete @imageServiceLayer
		# Called when Rendering Rule has changed or imageServiceUrl has changed
		setImageOrModifyRenderingRule: (renderingRule = new RasterFunction) ->
			unless @imageServiceLayer?
				# Create a new ImageServiceLayer
				@setImageLayer do =>
					# The ImageService Params. Either `null` or contains the Rendering Rule
					return null unless renderingRule?
					imageServiceParameters: (extend new ImageServiceParameters, renderingRule: renderingRule)
				, =>
					geometryService = new GeometryService @state.geometryServiceUrl
					connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
					# Project the ImageService extents to Map's SR
					geometryService.project (extend new ProjectParameters,
						geometries: [@imageServiceLayer.fullExtent, @imageServiceLayer.initialExtent]
						outSR: @map.extent.spatialReference
					), ([fullExtent, initialExtent]) =>
						@map.setExtent initialExtent
						@state.imageServiceExtent = fullExtent
			else # ImageServiceLayer exists
				@imageServiceLayer.setRenderingRule renderingRule # Modify the ImageServiceLayer's Rendering Rule
		# Called everytime a Pan / Zoom occurs in the Map
		refresh: (force = false, callback) ->
			return callback?() unless @state.imageServiceUrl? # Do nothing if there isn't an ImageServiceUrl specified
			unless @state.classificationEnabled # Classification Disabled
				@setImageOrModifyRenderingRule() if not @imageServiceLayer? or @imageServiceLayer.renderingRule?
				callback?()
			else # Classification Enabled
				return unless @state.featureGeos?
				geometryService = new GeometryService @state.geometryServiceUrl
				connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
				# Crop Feature Polygons to lie within Map's current view extent
				geometryService.intersect @state.featureGeos, @map.extent, (featuresInExtent) =>
					geometryService.areasAndLengths (extend new AreasAndLengthsParameters,
						calculationType: "planar"
						polygons: featuresInExtent
					), (areasAndLengths) =>
						unless @state.renderedFeatureIndex is indexOfMax areasAndLengths.areas and @state.clippedImageToSignaturePolygons is @state.clipToSignaturePolygons and force is false
							# Select the signature that corresponds to a feature polygon that has the most common area with the Map's current view extent
							@state.renderedFeatureIndex = indexOfMax areasAndLengths.areas
							state = @state
							parser = document.createElement "a"
							parser.href = @state.signatures[@state.renderedFeatureIndex]
							request.get(parser.href, headers: "X-Requested-With": null).then (gsg) =>
								@setImageOrModifyRenderingRule extend new RasterFunction,
									functionName: "funchain2",
									arguments:
										ClippingGeometry: if @state.clipToSignaturePolygons then @state.featureGeos[@state.renderedFeatureIndex] else extentToPolygon @state.imageServiceExtent
										SignatureFile: parser.href # Should be gsg but exportImage error
										Colormap:
											for cls in state.signatureClasses when cls.get("sigFile") is state.signatures[state.renderedFeatureIndex]
												[cls.get "sigValue"].concat color.fromHex(cls.get "sigColor").toRgb()
									variableName: "Raster"
								callback?()
						else
							callback?()
		# Called when Apply Changes button is clicked
		applyChanges: (callback) ->
			#Handle Errors
			return showError "Widget not bound to an instance of 'Map'." unless @map?
			return showError "GeometryService: Service URL Required." if @geometryServiceUrlInput.get("value") in ["", null, undefined]
			return showError "ImageServiceLayer: Service URL Required." if @imageServiceUrlInput.get("value") in ["", null, undefined]
			# Remove ImageServiceLayer if Url has changed
			if @state.imageServiceUrl isnt @imageServiceUrlInput.get "value"
					if @imageServiceLayer?
						@map.removeLayer @imageServiceLayer
						delete @imageServiceLayer
			# Set State Params
			extend @state,
				imageServiceUrl: @imageServiceUrlInput.get "value"
				geometryServiceUrl: @geometryServiceUrlInput.get "value"
				classificationEnabled: @classificationEnabledInput.get "checked"
				clipToSignaturePolygons: @clipToSignaturePolygonsInput.get "checked"
				features: null
				signatures: null
				renderedFeatureIndex: null
				clippedImageToSignaturePolygons: null
			# Enable / Disable Customize Classes Button
			@customizeClassesButton.set "disabled", not @state.classificationEnabled
			if @state.classificationEnabled
				fun1 = => # Portion invoked in sync or async. See below
					# Fetch Signatures and Polygons from feature layer
					signaturesLayer = new FeatureLayer @signaturesUrlInput.get("value"), outFields: ["SIGURL"]
					connect signaturesLayer, "onLoad", =>
						signaturesLayer.selectFeatures (extend new Query,
							geometry: @imageServiceLayer.fullExtent
							spatialRelationship: Query.SPATIAL_REL_INTERSECTS
						), FeatureLayer.SELECTION_NEW, (features) =>
							return showError "No features found within image service extent." if features.length is 0
							fun2 = =>
								@state.signatures = (f.attributes.SIGURL for f in features)
								geometryService = new GeometryService @state.geometryServiceUrl
								connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
								# Project Polygons to ImageService's SR
								geometryService.project (extend new ProjectParameters,
									geometries: (f.geometry for f in features)
									outSR: @map.spatialReference
								), (projectedGeos) =>
									# Crop the Projected Polygons to ImageService's extent
									geometryService.intersect projectedGeos, @imageServiceLayer.fullExtent, (boundedGeos) =>
										@state.featureGeos = boundedGeos
										@refresh false, callback # Finally call refresh()
							return fun2() if @state.signaturesUrl is @signaturesUrlInput.get "value"
							@state.signaturesUrl = @signaturesUrlInput.get "value"
							@classificationEnabledInput.set "disabled", false
							@classificationEnabledInput.set "checked", true
							# Create SignatureClassRows
							parsedClasses = []
							for f in features then do (f) =>
								signatureFileParser.getClasses f.attributes.SIGURL, (sigClasses) =>
									parsedClasses.push file: f.attributes.SIGURL, classes: sigClasses
									if parsedClasses.length is features.length
										data = []
										for {file, classes} in parsedClasses
											for cls, i in classes
												data.push d = new SignatureClassRow
													sigClass: cls.classname
													sigColor: color.fromHsv((if classes.length is 1 then 180 else i / classes.length * 360), 80, 80).toHex()
													sigValue: cls.value
													sigFile: file
													onColorChanged: => @refresh true
												d.startup()
										@state.signatureClasses = data
										fun2()
					connect signaturesLayer, "onError", (error) -> showError "FeatureLayer: #{error.message}"
				return fun1() if @imageServiceLayer? # ImageServiceLayer exists
				@setImageLayer null, => # ImageServiceLayer does not exist. Create New
					geometryService = new GeometryService @state.geometryServiceUrl
					connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
					# Project ImageService extents to Map's SR
					geometryService.project (extend new ProjectParameters,
						geometries: [@imageServiceLayer.fullExtent, @imageServiceLayer.initialExtent]
						outSR: @map.extent.spatialReference
					), ([fullExtent, initialExtent]) =>
						@map.setExtent initialExtent
						@state.imageServiceExtent = fullExtent
						setTimeout fun1, 500
			else # Classification Disabled
				@refresh false, callback # Call refresh()
		# Enable / Disable the ClipToSignaturePolygonsInput checkbox
		classificationEnabledInputValueChanged: (value) ->
			@clipToSignaturePolygonsInput.set "disabled", not value
		# On Show Signatures Dialog
		openSignaturesBox: ->
			fun1 = =>
				state = @state
				data = for cls in state.signatureClasses when cls.get("sigFile") is state.signatures[state.renderedFeatureIndex]
					cls
				@signaturesGrid.renderArray data
			return fun1() if @state.classificationEnabled
			@applyChanges fun1
		# On Close Signatures Dialog
		closeSignaturesBox: ->
			@signaturesGrid.refresh()