extend = (obj, mixin) ->
 	obj[name] = method for name, method of mixin        
 	obj

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
	showError = (content) ->
		errBox = new Dialog title: "Error", content: content
		errBox.startup()
		errBox.show()
		throw new Exception content
		errBox
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "classifyWidget"
		map: null
		imageServiceUrlInput: null
		signaturesUrlInput: null
		geometryServiceUrlInput: null
		imageServiceLayer: null
		state: {}
		constructor: ->
			this.watch "map", (attr, oldMap, newMap) =>
				dojo.connect newMap, "onExtentChange", @refresh.bind @
		setImageLayer: (options, callback) ->
			return showError "ImageServiceLayer: Service URL Required." if @state.imageServiceUrl in ["", null, undefined]
			@map.removeLayer @imageServiceLayer if @imageServiceLayer?
			@imageServiceLayer = new esri.layers.ArcGISImageServiceLayer @state.imageServiceUrl, options
			dojo.connect @imageServiceLayer, "onLoad", =>
				@map.addLayer @imageServiceLayer
				callback?()
			dojo.connect @imageServiceLayer, "onError", (error) -> showError "ImageServiceLayer: #{error.message}"
		setImageOrModifyRenderingRule: (renderingRule = new esri.layers.RasterFunction) ->
			unless @imageServiceLayer?
				@setImageLayer do =>
					return null unless renderingRule?
					imageServiceParameters: (extend new esri.layers.ImageServiceParameters, renderingRule: renderingRule)
				, =>
					geometryService = new esri.tasks.GeometryService @state.geometryServiceUrl
					dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
					geometryService.project (extend new esri.tasks.ProjectParameters,
						geometries: [@imageServiceLayer.initialExtent]
						outSR: @map.extent.spatialReference
					), ([extent]) =>
						@map.setExtent extent
			else
				@imageServiceLayer.setRenderingRule renderingRule
		refresh: ->
			return unless @state.imageServiceUrl?
			unless @state.classificationEnabled
				@setImageOrModifyRenderingRule() if not @imageServiceLayer? or @imageServiceLayer.renderingRule?
			else
				geometryService = new esri.tasks.GeometryService @state.geometryServiceUrl
				dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
				geometryService.intersect @state.features, @map.extent, (featuresInExtent) =>
					geometryService.areasAndLengths (extend new esri.tasks.AreasAndLengthsParameters,
						calculationType: "planar"
						polygons: featuresInExtent
					), (areasAndLengths) =>
						unless @state.renderedFeatureIndex is indexOfMax areasAndLengths.areas
							@state.renderedFeatureIndex = indexOfMax areasAndLengths.areas
							@setImageOrModifyRenderingRule extend new esri.layers.RasterFunction,
								functionName: "funchain1",
								arguments:
									ClippingGeometry: @state.features[@state.renderedFeatureIndex]
									SignatureFile: @state.signatures[@state.renderedFeatureIndex]
								variableName: "Raster"
		applyChanges: ->
			return showError "Widget not bound to an instance of 'esri/map'." unless @map?
			return showError "GeometryService: Service URL Required." if @geometryServiceUrlInput.get("value") in ["", null, undefined]
			return showError "ImageServiceLayer: Service URL Required." if @imageServiceUrlInput.get("value") in ["", null, undefined]
			return showError "Signatures: Service URL Required." if @signaturesUrlInput.get("value") in ["", null, undefined] and not @classificationEnabledInput.get "checked"
			extend @state,
				imageServiceUrl: @imageServiceUrlInput.get "value"
				signaturesUrl: @signaturesUrlInput.get "value"
				geometryServiceUrl: @geometryServiceUrlInput.get "value"
				classificationEnabled: @classificationEnabledInput.get "checked"
				features: null
				signatures: null
				renderedFeatureIndex: null
			if @state.classificationEnabled
				fun1 = =>
					signaturesLayer = new esri.layers.FeatureLayer @state.signaturesUrl, outFields: ["FID", "SIGURL"]
					dojo.connect signaturesLayer, "onLoad", =>
						signaturesLayer.selectFeatures (extend new esri.tasks.Query,
							geometry: @imageServiceLayer.fullExtent
							spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
						), esri.layers.FeatureLayer.SELECTION_NEW, (features) =>
							return showError "No features found within current view extent." if features.length is 0
							@state.signatures = (f.attributes.SIGURL for f in features)
							geometryService = new esri.tasks.GeometryService @state.geometryServiceUrl
							dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
							geometryService.intersect (f.geometry for f in features), @imageServiceLayer.fullExtent, (boundedFeatures) =>
								@state.features = boundedFeatures
								@refresh()
					dojo.connect signaturesLayer, "onError", (error) -> showError "FeatureLayer: #{error.message}"
				return fun1() if @imageServiceLayer?
				@setImageLayer null, =>
					geometryService = new esri.tasks.GeometryService @state.geometryServiceUrl
					dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
					geometryService.project (extend new esri.tasks.ProjectParameters,
						geometries: [@imageServiceLayer.initialExtent]
						outSR: @map.extent.spatialReference
					), ([extent]) =>
						@map.setExtent extent
						fun1()
			else
				@refresh()