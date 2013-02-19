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
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "classifyWidget"
		map: null
		_imageServiceUrlInput: null
		_signaturesUrlInput: null
		_imageServiceLayer: null
		_signaturesLayer: null
		_addImageServiceLayer: ->
			@map.removeLayer @_imageServiceLayer if @_imageServiceLayer?
			@_imageServiceLayer = new esri.layers.ArcGISImageServiceLayer @_imageServiceUrlInput.get "value"
			dojo.connect @_imageServiceLayer, "onLoad", =>
				@map.addLayer @_imageServiceLayer
				@map.setExtent @_imageServiceLayer.initialExtent
		_getSignaturesForExtent: ->
			@_signaturesLayer = new esri.layers.FeatureLayer @_signaturesUrlInput.get "value"
			dojo.connect @_signaturesLayer, "onLoad", =>
				@map.addLayer @_signaturesLayer
				console.log
					currentExtent: @map.extent
					signaturesWithinExtent: ()