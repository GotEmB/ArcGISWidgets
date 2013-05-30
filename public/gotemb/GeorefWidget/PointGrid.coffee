define [
	"dojo/_base/declare"
	"dijit/_WidgetBase"
	"dijit/_TemplatedMixin"
	"dijit/_WidgetsInTemplateMixin"
	"dojo/text!./PointGrid/templates/PointGrid.html"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "PointGrid"
		x: null
		y: null
		onPointChanged: null
		xInput: null
		yInput: null
		postCreate: ->
			@xInput.value = @x
			@yInput.value = @y
		valueChanged: ->
			@x = @xInput.value
			@y = @yInput.value
			@onPointChanged? x: @x, y: @y