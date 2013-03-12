###
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
###

define [
	"dojo/_base/declare"
	"dijit/_WidgetBase"
	"dijit/_TemplatedMixin"
	"dijit/_WidgetsInTemplateMixin"
	"dojo/text!./SignatureClassRow/templates/SignatureClassRow.html"
	"dojo/dom-style"
	"dojo/query"
	"dijit/form/DropDownButton"
	"dijit/ColorPalette"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, domStyle, query) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "SignatureClassRow"
		sigClass: ""
		sigColor: ""
		sigValue: NaN
		sigFile: ""
		onColorChanged: null
		constructor: ->
			@watch "sigColor", (attr, oldValue, newValue) =>
				domStyle.set query(".colorPreview", @domNode)[0], "background", newValue
				@onColorChanged?()
		postCreate: ->
			domStyle.set query(".colorPreview", @domNode)[0], "background", @sigColor
		colorChanged: (value) ->
			@set "sigColor", value