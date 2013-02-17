define [
	"dojo/_base/declare"
	"dijit/_WidgetBase"
	"dijit/_TemplatedMixin"
	"dojo/text!./ClassifyWidget/templates/ClassifyWidget.html"
	"dojo/dom-style"
	"dijit/layout/BorderContainer"
	"dijit/layout/ContentPane"
	"dijit/form/TextBox"
	"dijit/form/Button"
], (declare, _WidgetBase, _TemplatedMixin, template, domStyle) ->
	declare [_WidgetBase, _TemplatedMixin],
		templateString: template
		baseClass: "classifyWidget"