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
	"dijit/Dialog"	
	"dijit/layout/BorderContainer"
	"dijit/layout/ContentPane"
	"dijit/form/TextBox"
	"dijit/form/Button"
	"dijit/form/CheckBox"
	"esri/map"
	"esri/layers/FeatureLayer"
	"esri/tasks/query"
	"esri/tasks/geometry"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, Dialog) ->
	# Show an error box and log it to console
	showError = (content) ->
		errBox = new Dialog title: "Error", content: content
		errBox.startup()
		errBox.show()
		throw new Error content
		errBox
	# Convert an `esri.geometry.extent` to an `esri.geometry.polygon`
	extentToPolygon = (extent) ->
		polygon = new esri.geometry.Polygon extent.spatialReference
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
		baseClass: "classifyWidget"
		map: null # should be bound to an `esri.Map` instance before using the widget
		# Widget Inputs
		imageServiceUrlInput: null
		signaturesUrlInput: null
		geometryServiceUrlInput: null
		imageServiceLayer: null
		classificationEnabledInput: null
		clipToSignaturePolygonsInput: null
		state: {} # Contains the widget's current state
		constructor: ->
			# Bind the @refresh function to the Map's onExtentChange event
			this.watch "map", (attr, oldMap, newMap) =>
				dojo.connect newMap, "onExtentChange", @refresh.bind @
		# Enable / Disable the ClipToSignaturePolygonsInput checkbox
		classificationEnabledInputValueChanged: (value) ->
			@clipToSignaturePolygonsInput.set "disabled", not value
		# Sets the ImageServiceLayer with the url stored in the State
		setImageLayer: (options, callback) ->
			return showError "ImageServiceLayer: Service URL Required." if @state.imageServiceUrl in ["", null, undefined]
			@map.removeLayer @imageServiceLayer if @imageServiceLayer?
			@imageServiceLayer = new esri.layers.ArcGISImageServiceLayer @state.imageServiceUrl, options
			dojo.connect @imageServiceLayer, "onLoad", =>
				@map.addLayer @imageServiceLayer
				callback?()
			dojo.connect @imageServiceLayer, "onError", (error) =>
				showError "ImageServiceLayer: #{error.message}"
				delete @imageServiceLayer
		# Called when Rendering Rule has changed or imageServiceUrl has changed
		setImageOrModifyRenderingRule: (renderingRule = new esri.layers.RasterFunction) ->
			unless @imageServiceLayer?
				# Create a new ImageServiceLayer
				@setImageLayer do =>
					# The ImageService Params. Either `null` or contains the Rendering Rule
					return null unless renderingRule?
					imageServiceParameters: (extend new esri.layers.ImageServiceParameters, renderingRule: renderingRule)
				, =>
					geometryService = new esri.tasks.GeometryService @state.geometryServiceUrl
					dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
					# Project the ImageService extents to Map's SR
					geometryService.project (extend new esri.tasks.ProjectParameters,
						geometries: [@imageServiceLayer.fullExtent, @imageServiceLayer.initialExtent]
						outSR: @map.extent.spatialReference
					), ([fullExtent, initialExtent]) =>
						@map.setExtent initialExtent
						@state.imageServiceExtent = fullExtent
			else # ImageServiceLayer exists
				@imageServiceLayer.setRenderingRule renderingRule # Modify the ImageServiceLayer's Rendering Rule
		# Called everytime a Pan / Zoom occurs in the Map
		refresh: ->
			return unless @state.imageServiceUrl? # Do nothing if there isn't an ImageServiceUrl specified
			unless @state.classificationEnabled # Classification Disabled
				@setImageOrModifyRenderingRule() if not @imageServiceLayer? or @imageServiceLayer.renderingRule?
			else # Classification Enabled
				geometryService = new esri.tasks.GeometryService @state.geometryServiceUrl
				dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
				# Crop Feature Polygons to lie within Map's current view extent
				geometryService.intersect @state.featureGeos, @map.extent, (featuresInExtent) =>
					geometryService.areasAndLengths (extend new esri.tasks.AreasAndLengthsParameters,
						calculationType: "planar"
						polygons: featuresInExtent
					), (areasAndLengths) =>
						# Select the signature that corresponds to a feature polygon that has the most common area with the Map's current view extent
						unless @state.renderedFeatureIndex is indexOfMax areasAndLengths.areas and @state.clippedImageToSignaturePolygons is @state.clipToSignaturePolygons
							@state.renderedFeatureIndex = indexOfMax areasAndLengths.areas
							@setImageOrModifyRenderingRule extend new esri.layers.RasterFunction,
								functionName: "funchain1",
								arguments:
									ClippingGeometry: if @state.clipToSignaturePolygons then @state.featureGeos[@state.renderedFeatureIndex] else extentToPolygon @state.imageServiceExtent
									SignatureFile: @state.signatures[@state.renderedFeatureIndex]
								variableName: "Raster"
		# Called when Apply Changes button is clicked
		applyChanges: ->
			#Handle Errors
			return showError "Widget not bound to an instance of 'esri/map'." unless @map?
			return showError "GeometryService: Service URL Required." if @geometryServiceUrlInput.get("value") in ["", null, undefined]
			return showError "ImageServiceLayer: Service URL Required." if @imageServiceUrlInput.get("value") in ["", null, undefined]
			return showError "Signatures: Service URL Required." if @signaturesUrlInput.get("value") in ["", null, undefined] and @classificationEnabledInput.get "checked"
			# Remove ImageServiceLayer if Url has changed
			if @state.imageServiceUrl isnt @imageServiceUrlInput.get "value"
					if @imageServiceLayer?
						@map.removeLayer @imageServiceLayer
						delete @imageServiceLayer
			# Set State Params
			extend @state,
				imageServiceUrl: @imageServiceUrlInput.get "value"
				signaturesUrl: @signaturesUrlInput.get "value"
				geometryServiceUrl: @geometryServiceUrlInput.get "value"
				classificationEnabled: @classificationEnabledInput.get "checked"
				clipToSignaturePolygons: @clipToSignaturePolygonsInput.get "checked"
				features: null
				signatures: null
				renderedFeatureIndex: null
				clippedImageToSignaturePolygons: null
			if @state.classificationEnabled
				fun1 = => # Portion invoked in sync or async. See below
					# Fetch Signatures and Polygons from feature layer
					signaturesLayer = new esri.layers.FeatureLayer @state.signaturesUrl, outFields: ["SIGURL"]
					dojo.connect signaturesLayer, "onLoad", =>
						signaturesLayer.selectFeatures (extend new esri.tasks.Query,
							geometry: @imageServiceLayer.fullExtent
							spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
						), esri.layers.FeatureLayer.SELECTION_NEW, (features) =>
							return showError "No features found within current view extent." if features.length is 0
							@state.signatures = (f.attributes.SIGURL for f in features)
							geometryService = new esri.tasks.GeometryService @state.geometryServiceUrl
							dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
							# Project Polygons to ImageService's SR
							geometryService.project (extend new esri.tasks.ProjectParameters,
								geometries: (f.geometry for f in features)
								outSR: @map.spatialReference
							), (projectedGeos) =>
								# Crop the Projected Polygons to ImageService's extent
								geometryService.intersect projectedGeos, @imageServiceLayer.fullExtent, (boundedGeos) =>
									@state.featureGeos = boundedGeos
									@refresh() # Finally call refresh()
					dojo.connect signaturesLayer, "onError", (error) -> showError "FeatureLayer: #{error.message}"
				return fun1() if @imageServiceLayer? # ImageServiceLayer exists
				@setImageLayer null, => # ImageServiceLayer does not exist. Create New
					geometryService = new esri.tasks.GeometryService @state.geometryServiceUrl
					dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
					geometryService.project (extend new esri.tasks.ProjectParameters,
						geometries: [@imageServiceLayer.initialExtent]
						outSR: @map.extent.spatialReference
					), ([extent]) =>
						@map.setExtent extent
						fun1()
			else # Classification Disabled
				@refresh() # Call refresh()