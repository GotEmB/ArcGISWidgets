define [
	"dojo/_base/declare"
	"dijit/_WidgetBase"
	"dijit/_TemplatedMixin"
	"dijit/_WidgetsInTemplateMixin"
	"dojo/text!./ClassifyWidget/templates/ClassifyWidget.html"
	"dojo/on"
	"dijit/layout/BorderContainer"
	"dijit/layout/ContentPane"
	"dijit/form/TextBox"
	"dijit/form/Button"
	"esri/map"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, connect) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "classifyWidget"
		map: null
		_imageServiceUrlInput: null
		_featureServiceUrlInput: null
		_classify: ->
			nl = new esri.layers.ArcGISImageServiceLayer @_imageServiceUrlInput.get "value"
			@map.addLayer nl
			connect @map, "LayerAdd", =>
				@map.setExtent nl.initialExtent