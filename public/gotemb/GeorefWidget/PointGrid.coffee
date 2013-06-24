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
			@x = Number @xInput.value = (Number @x).toFixed 1
			@y = Number @yInput.value = (Number @y).toFixed 1
		valueChanged: ->
			@x = Number @xInput.value = (Number @xInput.value).toFixed 1
			@y = Number @yInput.value = (Number @yInput.value).toFixed 1
			@onPointChanged? x: @x, y: @y
		setPoint: ({x, y})->
			@x = Number @xInput.value = (Number x).toFixed 1
			@y = Number @yInput.value = (Number y).toFixed 1