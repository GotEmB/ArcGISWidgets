extend = (obj, mixin) ->
 	obj[name] = method for name, method of mixin        
 	obj

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
		_imageServiceUrlInput: null
		_signaturesUrlInput: null
		_geometryServiceUrlInput: null
		_imageServiceLayer: null
		_setImageLayer: (options, callback) ->
			return showError "ImageServiceLayer: Service URL Required." if @_imageServiceUrlInput.get("value") in ["", null, undefined]
			@map.removeLayer @_imageServiceLayer if @_imageServiceLayer?
			@_imageServiceLayer = new esri.layers.ArcGISImageServiceLayer (@_imageServiceUrlInput.get "value"), options
			dojo.connect @_imageServiceLayer, "onLoad", =>
				@map.addLayer @_imageServiceLayer
				callback?()
			dojo.connect @_imageServiceLayer, "onError", (error) -> showError "ImageServiceLayer: #{error.message}"
		_addImageServiceLayer: ->
			return showError "GeometryService: Service URL Required." if @_geometryServiceUrlInput.get("value") in ["", null, undefined]
			@_setImageLayer null, =>
				geometryService = new esri.tasks.GeometryService @_geometryServiceUrlInput.get "value"
				dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
				geometryService.project (extend new esri.tasks.ProjectParameters,
					geometries: [@_imageServiceLayer.initialExtent]
					outSR: @map.extent.spatialReference
				), ([extent]) =>
					@map.setExtent extent
		_clipImageToSignatureFeatures: ->
			return showError "FeatureLayer: Service URL Required." if @_signaturesUrlInput.get("value") in ["", null, undefined]
			return showError "GeometryService: Service URL Required." if @_geometryServiceUrlInput.get("value") in ["", null, undefined]
			signaturesLayer = new esri.layers.FeatureLayer (@_signaturesUrlInput.get "value"), outFields: ["FID", "SIGURL"]
			dojo.connect signaturesLayer, "onLoad", =>
				signaturesLayer.selectFeatures (extend new esri.tasks.Query,
					geometry: @map.extent
					spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
				), esri.layers.FeatureLayer.SELECTION_NEW, (features) =>
					return showError "No features found within current view extent." if features.length is 0
					geometryService = new esri.tasks.GeometryService @_geometryServiceUrlInput.get "value"
					dojo.connect geometryService, "onError", (error) -> showError "GeometryService: #{error.message}"
					geometryService.union (f.geometry for f in features), (geo1) =>
						geometryService.intersect [geo1], @_imageServiceLayer.fullExtent, ([geo2]) =>
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
		_getClassifiedImage: ->
			return showError "FeatureLayer: Service URL Required." if @_signaturesUrlInput.get("value") in ["", null, undefined]
			return showError "GeometryService: Service URL Required." if @_geometryServiceUrlInput.get("value") in ["", null, undefined]
			signaturesLayer = new esri.layers.FeatureLayer (@_signaturesUrlInput.get "value"), outFields: ["FID", "SIGURL"]
			dojo.connect signaturesLayer, "onLoad", =>
				signaturesLayer.selectFeatures (extend new esri.tasks.Query,
					geometry: @map.extent
					spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
				), esri.layers.FeatureLayer.SELECTION_NEW, (features) =>
					@_setImageLayer
						imageServiceParameters: (extend new esri.layers.ImageServiceParameters,
							renderingRule: (extend new esri.layers.RasterFunction,
								functionName: "RFT_MLC2class_CLRrgbp",
								arguments:
									SignatureFile: """
										# Signatures
										1 3 6 6
										1 798 000_1
										50.97243 46.11153 53.27193 57.02757 88.12657 66.09273
										1 6.97038 7.51374 13.12043 3.85271 16.21303 20.65877
										2 7.51374 10.47312 16.91945 5.87020 20.41498 26.05489
										3 13.12043 16.91945 30.98368 8.56840 34.67821 45.12030
										4 3.85271 5.87020 8.56840 8.48857 11.91495 13.15679
										5 16.21303 20.41498 34.67821 11.91495 48.82587 59.29440
										6 20.65877 26.05489 45.12030 13.15679 59.29440 76.68650
										2 287 000_2
										67.56446 71.88502 90.97561 81.65505 113.58885 98.83275
										1 7.67328 8.79940 12.53829 4.44714 6.58953 5.44788
										2 8.79940 13.20701 18.15802 5.85530 9.81969 8.19749
										3 12.53829 18.15802 28.96793 8.02652 15.67875 13.81059
										4 4.44714 5.85530 8.02652 6.33864 3.23880 1.72532
										5 6.58953 9.81969 15.67875 3.23880 15.46673 14.41002
										6 5.44788 8.19749 13.81059 1.72532 14.41002 17.55235
										3 53 000_3
										41.13208 35.83019 29.26415 99.05660 55.98113 29.24528
										1 1.73222 1.15747 1.88752 -2.98839 2.67562 2.44775
										2 1.15747 1.72061 1.33418 -1.72097 2.03520 1.90784
										3 1.88752 1.33418 4.35196 -8.22678 4.71662 4.47242
										4 -2.98839 -1.72097 -8.22678 43.16981 -16.07583 -14.14877
										5 2.67562 2.03520 4.71662 -16.07583 9.90348 7.67779
										6 2.44775 1.90784 4.47242 -14.14877 7.67779 7.95791
									"""
								variableName: "Raster"
							)
						)