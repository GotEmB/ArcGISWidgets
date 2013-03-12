// Generated by CoffeeScript 1.6.1

/*
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
*/


(function() {

  define(["dojo/_base/declare", "dijit/_WidgetBase", "dijit/_TemplatedMixin", "dijit/_WidgetsInTemplateMixin", "dojo/text!./SignatureClassRow/templates/SignatureClassRow.html", "dojo/dom-style", "dojo/query", "dijit/form/DropDownButton", "dijit/ColorPalette"], function(declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, domStyle, query) {
    return declare([_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin], {
      templateString: template,
      baseClass: "SignatureClassRow",
      sigClass: "",
      sigColor: "",
      sigValue: NaN,
      sigFile: "",
      constructor: function() {
        var _this = this;
        return this.watch("sigColor", function(attr, oldValue, newValue) {
          return domStyle.set(query(".colorPreview", _this.domNode)[0], "background", newValue);
        });
      },
      postCreate: function() {
        return domStyle.set(query(".colorPreview", this.domNode)[0], "background", this.sigColor);
      },
      colorChanged: function(value) {
        return this.set("sigColor", value);
      }
    });
  });

}).call(this);
