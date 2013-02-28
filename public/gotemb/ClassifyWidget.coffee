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
	"dijit/form/DropDownButton"
	"dijit/DropDownMenu"
	"dijit/MenuItem"
	"dijit/MenuSeparator"
	"esri/map"
	"esri/layers/FeatureLayer"
	"esri/tasks/query"
	"esri/tasks/geometry"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, Dialog) ->
	showError = (content) ->
		errBox = new Dialog title: "Error", content: content
		errBox.startup()
		errBox.show()
		errBox
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "classifyWidget"
		map: null
		imageServiceUrlInput: null
		signaturesUrlInput: null
		geometryServiceUrlInput: null
		imageServiceLayer: null
		_setImageLayer: (options, callback) ->
			return showError "ImageServiceLayer: Service URL Required." if @imageServiceUrlInput.get("value") in ["", null, undefined]
			@map.removeLayer @imageServiceLayer if @imageServiceLayer?
			@imageServiceLayer = new esri.layers.ArcGISImageServiceLayer (@imageServiceUrlInput.get "value"), options
			dojo.connect @imageServiceLayer, "onLoad", =>
				@map.addLayer @imageServiceLayer
				callback?()
			dojo.connect @imageServiceLayer, "onError", (error) -> showError "ImageServiceLayer: #{error.message}"
		addImageServiceLayer: ->
			return showError "GeometryService: Service URL Required." if @geometryServiceUrlInput.get("value") in ["", null, undefined]
			@_setImageLayer null, =>
				geometryService = new esri.tasks.GeometryService @geometryServiceUrlInput.get "value"
				dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
				geometryService.project (extend new esri.tasks.ProjectParameters,
					geometries: [@imageServiceLayer.initialExtent]
					outSR: @map.extent.spatialReference
				), ([extent]) =>
					@map.setExtent extent
		clipImageToSignatureFeatures: ->
			return showError "FeatureLayer: Service URL Required." if @signaturesUrlInput.get("value") in ["", null, undefined]
			return showError "GeometryService: Service URL Required." if @geometryServiceUrlInput.get("value") in ["", null, undefined]
			fun1 = =>
				signaturesLayer = new esri.layers.FeatureLayer (@signaturesUrlInput.get "value"), outFields: ["FID", "SIGURL"]
				dojo.connect signaturesLayer, "onLoad", =>
					signaturesLayer.selectFeatures (extend new esri.tasks.Query,
						geometry: @map.extent
						spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
					), esri.layers.FeatureLayer.SELECTION_NEW, (features) =>
						return showError "No features found within current view extent." if features.length is 0
						geometryService = new esri.tasks.GeometryService @geometryServiceUrlInput.get "value"
						dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
						geometryService.union (f.geometry for f in features), (geo1) =>
							geometryService.intersect [geo1], @imageServiceLayer.fullExtent, ([geo2]) =>
								return showError "No features found within ImageServiceLayer Extent." unless geo2?.rings?.length > 0
								geometryService.intersect [geo2], @map.extent, ([geo3]) =>
									return showError "No features found within ImageServiceLayer and current view Extent." unless geo3?.rings?.length > 0
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
				dojo.connect signaturesLayer, "onError", (error) -> showError "FeatureLayer: #{error.message}"
			return fun1() if @imageServiceLayer?
			@_setImageLayer null, fun1
		getClassifiedImage: ->
			return showError "FeatureLayer: Service URL Required." if @signaturesUrlInput.get("value") in ["", null, undefined]
			return showError "GeometryService: Service URL Required." if @geometryServiceUrlInput.get("value") in ["", null, undefined]
			fun1 = =>
				signaturesLayer = new esri.layers.FeatureLayer (@signaturesUrlInput.get "value"), outFields: ["FID", "SIGURL"]
				dojo.connect signaturesLayer, "onLoad", =>
					signaturesLayer.selectFeatures (extend new esri.tasks.Query,
						geometry: @map.extent
						spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
					), esri.layers.FeatureLayer.SELECTION_NEW, (features) =>
						return showError "No features found within current view extent." if features.length is 0
						geometryService = new esri.tasks.GeometryService @geometryServiceUrlInput.get "value"
						dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
						geometryService.union (f.geometry for f in features), (geo1) =>
							geometryService.intersect [geo1], @imageServiceLayer.fullExtent, ([geo2]) =>
								return showError "No features found within ImageServiceLayer Extent." unless geo2?.rings?.length > 0
								geometryService.intersect [geo2], @map.extent, ([geo3]) =>
									return showError "No features found within ImageServiceLayer and current view Extent." unless geo3?.rings?.length > 0
									geometryService.intersect (feature.geometry for feature in features), geo3, (featureGeosInExtent) =>
										geometryService.areasAndLengths (extend new esri.tasks.AreasAndLengthsParameters,
											calculationType: "planar"
											polygons: featureGeosInExtent
										), (areasAndLengths) =>
											@_setImageLayer
												imageServiceParameters: (extend new esri.layers.ImageServiceParameters,
													renderingRule: (extend new esri.layers.RasterFunction,
														functionName: "funchain1",
														arguments:
															ClippingGeometry: featureGeosInExtent[indexOfMax areasAndLengths.areas]
															SignatureFile: features[indexOfMax areasAndLengths.areas].attributes.SIGURL
														variableName: "Raster"
													)
												)
											console.log features[indexOfMax areasAndLengths.areas].attributes.SIGURL
				dojo.connect signaturesLayer, "onError", (error) -> showError "FeatureLayer: #{error.message}"
			return fun1() if @imageServiceLayer?
			@_setImageLayer null, fun1