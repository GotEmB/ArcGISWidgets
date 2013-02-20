extend = (obj, mixin) ->
 	obj[name] = method for name, method of mixin        
 	obj

define [
	"dojo/_base/declare"
	"dijit/_WidgetBase"
	"dijit/_TemplatedMixin"
	"dijit/_WidgetsInTemplateMixin"
	"dojo/text!./ClassifyWidget/templates/ClassifyWidget.html"
	"dijit/layout/BorderContainer"
	"dijit/layout/ContentPane"
	"dijit/form/TextBox"
	"dijit/form/Button"
	"esri/map"
	"esri/layers/FeatureLayer"
	"esri/tasks/query"
	"esri/tasks/geometry"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "classifyWidget"
		map: null
		_imageServiceUrlInput: null
		_signaturesUrlInput: null
		_geometryServiceUrlInput: null
		_imageServiceLayer: null
		_setImageLayer: (options, callback) ->
			@map.removeLayer @_imageServiceLayer if @_imageServiceLayer?
			@_imageServiceLayer = new esri.layers.ArcGISImageServiceLayer (@_imageServiceUrlInput.get "value"), options
			dojo.connect @_imageServiceLayer, "onLoad", =>
				@map.addLayer @_imageServiceLayer
				callback?()
		_addImageServiceLayer: ->
			@_setImageLayer null, =>
				@map.setExtent @_imageServiceLayer.initialExtent
		_clipImageToSignatureFeatures: ->
			signaturesLayer = new esri.layers.FeatureLayer (@_signaturesUrlInput.get "value"), outFields: ["FID", "SIGURL"]
			dojo.connect signaturesLayer, "onLoad", =>
				signaturesLayer.selectFeatures (extend new esri.tasks.Query,
					geometry: @map.extent
					spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
				), esri.layers.FeatureLayer.SELECTION_NEW, (features) =>
					geometryService = new esri.tasks.GeometryService @_geometryServiceUrlInput.get "value"
					geometryService.union (f.geometry for f in features), (geo1) =>
						geometryService.intersect [geo1], @_imageServiceLayer.fullExtent, ([geo2]) =>
							geometryService.intersect [geo2], @map.extent, ([geo3]) =>
								@_setImageLayer
									imageServiceParameters: (extend new esri.layers.ImageServiceParameters,
										renderingRule: (extend new esri.layers.RasterFunction,
											functionName: "Clip",
											arguments:
												ClippingGeometry: geo3
												ClippingType: 1
											variableName: "Raster"
										)
									)