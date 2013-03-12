// Generated by CoffeeScript 1.5.0
/*
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
*/

var extend, indexOfMax;

extend = function(obj, mixin) {
  var method, name;
  for (name in mixin) {
    method = mixin[name];
    obj[name] = method;
  }
  return obj;
};

indexOfMax = function(arr) {
  var a, i, idx, max, _i, _len;
  max = -Infinity;
  idx = -1;
  for (i = _i = 0, _len = arr.length; _i < _len; i = ++_i) {
    a = arr[i];
    if (a > max) {
      max = a;
      idx = i;
    }
  }
  return idx;
};

define(["dojo/_base/declare", "dijit/_WidgetBase", "dijit/_TemplatedMixin", "dijit/_WidgetsInTemplateMixin", "dojo/text!./ClassifyWidget/templates/ClassifyWidget.html", "dijit/Dialog", "./ClassifyWidget/SignatureClassRow", "./ClassifyWidget/signatureFileParser", "dijit/form/TextBox", "dijit/form/Button", "dijit/form/CheckBox", "esri/map", "esri/layers/FeatureLayer", "esri/tasks/query", "esri/tasks/geometry", "dgrid/Grid"], function(declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, Dialog, SignatureClassRow, signatureFileParser) {
  var extentToPolygon, showError;
  showError = function(content) {
    var errBox;
    errBox = new Dialog({
      title: "Error",
      content: content
    });
    errBox.startup();
    errBox.show();
    console.error(new Error(content));
    return errBox;
  };
  extentToPolygon = function(extent) {
    var polygon;
    polygon = new esri.geometry.Polygon(extent.spatialReference);
    polygon.addRing([[extent.xmin, extent.ymin], [extent.xmin, extent.ymax], [extent.xmax, extent.ymax], [extent.xmax, extent.ymin], [extent.xmin, extent.ymin]]);
    return polygon;
  };
  return declare([_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin], {
    templateString: template,
    baseClass: "ClassifyWidget",
    map: null,
    imageServiceUrlInput: null,
    geometryServiceUrlInput: null,
    imageServiceLayer: null,
    classificationEnabledInput: null,
    clipToSignaturePolygonsInput: null,
    signaturesBox: null,
    signaturesUrlInput: null,
    signaturesGrid: null,
    loadSignaturesButton: null,
    customizeClassesButton: null,
    state: {},
    constructor: function() {
      var _this = this;
      return this.watch("map", function(attr, oldMap, newMap) {
        return dojo.connect(newMap, "onExtentChange", _this.refresh.bind(_this));
      });
    },
    postCreate: function() {
      return this.signaturesGrid.set("columns", {
        "class": {
          label: "Signature Class",
          renderCell: function(object, value, node) {
            node.style.verticalAlign = "middle";
            return node.textContent = object.get("sigClass");
          }
        },
        color: {
          label: "Color",
          renderCell: function(object) {
            return object.domNode;
          }
        }
      });
    },
    setImageLayer: function(options, callback) {
      var _ref,
        _this = this;
      if ((_ref = this.state.imageServiceUrl) === "" || _ref === null || _ref === (void 0)) {
        return showError("ImageServiceLayer: Service URL Required.");
      }
      if (this.imageServiceLayer != null) {
        this.map.removeLayer(this.imageServiceLayer);
      }
      this.imageServiceLayer = new esri.layers.ArcGISImageServiceLayer(this.state.imageServiceUrl, options);
      dojo.connect(this.imageServiceLayer, "onLoad", function() {
        _this.map.addLayer(_this.imageServiceLayer);
        return typeof callback === "function" ? callback() : void 0;
      });
      return dojo.connect(this.imageServiceLayer, "onError", function(error) {
        showError("ImageServiceLayer: " + error.message);
        return delete _this.imageServiceLayer;
      });
    },
    setImageOrModifyRenderingRule: function(renderingRule) {
      var _this = this;
      if (renderingRule == null) {
        renderingRule = new esri.layers.RasterFunction;
      }
      if (this.imageServiceLayer == null) {
        return this.setImageLayer((function() {
          if (renderingRule == null) {
            return null;
          }
          return {
            imageServiceParameters: extend(new esri.layers.ImageServiceParameters, {
              renderingRule: renderingRule
            })
          };
        })(), function() {
          var geometryService;
          geometryService = new esri.tasks.GeometryService(_this.state.geometryServiceUrl);
          dojo.connect(geometryService, "onError", function(error) {
            return showError("GeometryService: " + error.message);
          });
          return geometryService.project(extend(new esri.tasks.ProjectParameters, {
            geometries: [_this.imageServiceLayer.fullExtent, _this.imageServiceLayer.initialExtent],
            outSR: _this.map.extent.spatialReference
          }), function(_arg) {
            var fullExtent, initialExtent;
            fullExtent = _arg[0], initialExtent = _arg[1];
            _this.map.setExtent(initialExtent);
            return _this.state.imageServiceExtent = fullExtent;
          });
        });
      } else {
        return this.imageServiceLayer.setRenderingRule(renderingRule);
      }
    },
    refresh: function() {
      var geometryService,
        _this = this;
      if (this.state.imageServiceUrl == null) {
        return;
      }
      if (!this.state.classificationEnabled) {
        if ((this.imageServiceLayer == null) || (this.imageServiceLayer.renderingRule != null)) {
          return this.setImageOrModifyRenderingRule();
        }
      } else {
        geometryService = new esri.tasks.GeometryService(this.state.geometryServiceUrl);
        dojo.connect(geometryService, "onError", function(error) {
          return showError("GeometryService: " + error.message);
        });
        return geometryService.intersect(this.state.featureGeos, this.map.extent, function(featuresInExtent) {
          return geometryService.areasAndLengths(extend(new esri.tasks.AreasAndLengthsParameters, {
            calculationType: "planar",
            polygons: featuresInExtent
          }), function(areasAndLengths) {
            var cls, state;
            if (_this.state.renderedFeatureIndex !== indexOfMax(areasAndLengths.areas && _this.state.clippedImageToSignaturePolygons === _this.state.clipToSignaturePolygons)) {
              _this.state.renderedFeatureIndex = indexOfMax(areasAndLengths.areas);
              _this.setImageOrModifyRenderingRule(extend(new esri.layers.RasterFunction, {
                functionName: "funchain2",
                "arguments": {
                  ClippingGeometry: _this.state.clipToSignaturePolygons ? _this.state.featureGeos[_this.state.renderedFeatureIndex] : extentToPolygon(_this.state.imageServiceExtent),
                  SignatureFile: _this.state.signatures[_this.state.renderedFeatureIndex],
                  Colormap: [[0, 255, 0, 0], [1, 0, 255, 0], [2, 0, 0, 255], [3, 255, 255, 0], [4, 255, 0, 255], [5, 0, 255, 255]]
                },
                variableName: "Raster"
              }));
              _this.signaturesGrid.refresh();
              state = _this.state;
              return _this.signaturesGrid.renderArray((function() {
                var _i, _len, _ref, _results;
                _ref = state.signatureClasses;
                _results = [];
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  cls = _ref[_i];
                  if (cls.get("sigFile") === state.signatures[state.renderedFeatureIndex]) {
                    _results.push(cls);
                  }
                }
                return _results;
              })());
            }
          });
        });
      }
    },
    applyChanges: function(callback) {
      var fun1, _ref, _ref1,
        _this = this;
      if (this.map == null) {
        return showError("Widget not bound to an instance of 'esri/map'.");
      }
      if ((_ref = this.geometryServiceUrlInput.get("value")) === "" || _ref === null || _ref === (void 0)) {
        return showError("GeometryService: Service URL Required.");
      }
      if ((_ref1 = this.imageServiceUrlInput.get("value")) === "" || _ref1 === null || _ref1 === (void 0)) {
        return showError("ImageServiceLayer: Service URL Required.");
      }
      if (this.state.imageServiceUrl !== this.imageServiceUrlInput.get("value")) {
        if (this.imageServiceLayer != null) {
          this.map.removeLayer(this.imageServiceLayer);
          delete this.imageServiceLayer;
        }
      }
      extend(this.state, {
        imageServiceUrl: this.imageServiceUrlInput.get("value"),
        geometryServiceUrl: this.geometryServiceUrlInput.get("value"),
        classificationEnabled: this.classificationEnabledInput.get("checked"),
        clipToSignaturePolygons: this.clipToSignaturePolygonsInput.get("checked"),
        features: null,
        signatures: null,
        renderedFeatureIndex: null,
        clippedImageToSignaturePolygons: null
      });
      if (this.state.classificationEnabled) {
        fun1 = function() {
          var signaturesLayer;
          signaturesLayer = new esri.layers.FeatureLayer(_this.state.signaturesUrl, {
            outFields: ["SIGURL"]
          });
          dojo.connect(signaturesLayer, "onLoad", function() {
            return signaturesLayer.selectFeatures(extend(new esri.tasks.Query, {
              geometry: _this.imageServiceLayer.fullExtent,
              spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
            }), esri.layers.FeatureLayer.SELECTION_NEW, function(features) {
              var f, geometryService;
              if (features.length === 0) {
                return showError("No features found within image service extent.");
              }
              _this.state.signatures = (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = features.length; _i < _len; _i++) {
                  f = features[_i];
                  _results.push(f.attributes.SIGURL);
                }
                return _results;
              })();
              geometryService = new esri.tasks.GeometryService(_this.state.geometryServiceUrl);
              dojo.connect(geometryService, "onError", function(error) {
                return showError("GeometryService: " + error.message);
              });
              return geometryService.project(extend(new esri.tasks.ProjectParameters, {
                geometries: (function() {
                  var _i, _len, _results;
                  _results = [];
                  for (_i = 0, _len = features.length; _i < _len; _i++) {
                    f = features[_i];
                    _results.push(f.geometry);
                  }
                  return _results;
                })(),
                outSR: _this.map.spatialReference
              }), function(projectedGeos) {
                return geometryService.intersect(projectedGeos, _this.imageServiceLayer.fullExtent, function(boundedGeos) {
                  _this.state.featureGeos = boundedGeos;
                  _this.refresh();
                  return typeof callback === "function" ? callback() : void 0;
                });
              });
            });
          });
          return dojo.connect(signaturesLayer, "onError", function(error) {
            return showError("FeatureLayer: " + error.message);
          });
        };
        if (this.imageServiceLayer != null) {
          return fun1();
        }
        return this.setImageLayer(null, function() {
          var geometryService;
          geometryService = new esri.tasks.GeometryService(_this.state.geometryServiceUrl);
          dojo.connect(geometryService, "onError", function(error) {
            return showError("GeometryService: " + error.message);
          });
          return geometryService.project(extend(new esri.tasks.ProjectParameters, {
            geometries: [_this.imageServiceLayer.fullExtent, _this.imageServiceLayer.initialExtent],
            outSR: _this.map.extent.spatialReference
          }), function(_arg) {
            var fullExtent, initialExtent;
            fullExtent = _arg[0], initialExtent = _arg[1];
            _this.map.setExtent(initialExtent);
            _this.state.imageServiceExtent = fullExtent;
            return fun1();
          });
        });
      } else {
        this.refresh();
        return typeof callback === "function" ? callback() : void 0;
      }
    },
    classificationEnabledInputValueChanged: function(value) {
      this.clipToSignaturePolygonsInput.set("disabled", !value);
      return this.customizeClassesButton.set("disabled", !value);
    },
    openSignaturesBox: function() {
      var fun1,
        _this = this;
      fun1 = function() {
        _this.signaturesBox.show();
        return _this.signaturesGrid.resize();
      };
      if (this.classificationEnabled) {
        return fun1();
      }
      return this.applyChanges(fun1);
    },
    signaturesUrlInputValueChanged: function(value) {
      if (value === this.state.signaturesUrl) {
        return;
      }
      this.loadSignaturesButton.set("disabled", false);
      this.classificationEnabledInput.set("disabled", true);
      return this.clipToSignaturePolygonsInput.set("disabled", true);
    },
    loadSignatures: function() {
      var signaturesLayer, _ref,
        _this = this;
      if (((_ref = this.signaturesUrlInput.get("value")) === "" || _ref === null || _ref === (void 0)) && this.classificationEnabledInput.get("checked")) {
        return showError("Signatures: Service URL Required.");
      }
      signaturesLayer = new esri.layers.FeatureLayer(this.signaturesUrlInput.get("value"), {
        outFields: ["SIGURL"]
      });
      return dojo.connect(signaturesLayer, "onLoad", function() {
        return signaturesLayer.selectFeatures(extend(new esri.tasks.Query, {
          geometry: signaturesLayer.fullExtent,
          spatialRelationship: esri.tasks.Query.SPATIAL_REL_INTERSECTS
        }), esri.layers.FeatureLayer.SELECTION_NEW, function(features) {
          var f, parsedClasses, _i, _len, _results;
          if (features.length === 0) {
            return showError("No features found within image service extent.");
          }
          _this.state.signaturesUrl = _this.signaturesUrlInput.get("value");
          _this.loadSignaturesButton.set("disabled", true);
          _this.classificationEnabledInput.set("disabled", false);
          if (_this.classificationEnabledInput.get("value")) {
            _this.clipToSignaturePolygonsInput.set("disabled", false);
          }
          if (_this.classificationEnabledInput.get("value")) {
            _this.customizeClassesButton.set("disabled", false);
          }
          parsedClasses = [];
          _results = [];
          for (_i = 0, _len = features.length; _i < _len; _i++) {
            f = features[_i];
            _results.push((function(f) {
              return signatureFileParser.getClasses(f.attributes.SIGURL, function(sigClasses) {
                var classes, cls, d, data, file, _j, _k, _len1, _len2, _ref1;
                parsedClasses.push({
                  file: f.attributes.SIGURL,
                  classes: sigClasses
                });
                if (parsedClasses.length === features.length) {
                  data = [];
                  for (_j = 0, _len1 = parsedClasses.length; _j < _len1; _j++) {
                    _ref1 = parsedClasses[_j], file = _ref1.file, classes = _ref1.classes;
                    for (_k = 0, _len2 = classes.length; _k < _len2; _k++) {
                      cls = classes[_k];
                      data.push(d = new SignatureClassRow({
                        sigClass: cls.classname,
                        sigColor: "green",
                        sigValue: cls.value,
                        sigFile: file
                      }));
                      d.startup();
                    }
                  }
                  return _this.state.signatureClasses = data;
                }
              });
            })(f));
          }
          return _results;
        });
      });
    },
    dismissSignaturesBox: function() {
      return this.signaturesBox.hide();
    }
  });
});
