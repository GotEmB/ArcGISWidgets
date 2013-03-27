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

define(["dojo/_base/declare", "dijit/_WidgetBase", "dijit/_TemplatedMixin", "dijit/_WidgetsInTemplateMixin", "dojo/text!./ClassifyWidget/templates/ClassifyWidget.html", "dojo/_base/connect", "dijit/Dialog", "gotemb/ClassifyWidget/SignatureClassRow", "gotemb/ClassifyWidget/signatureFileParser", "dojox/color", "esri/geometry/Polygon", "esri/layers/ArcGISImageServiceLayer", "esri/layers/RasterFunction", "esri/layers/ImageServiceParameters", "esri/tasks/GeometryService", "esri/tasks/ProjectParameters", "esri/tasks/AreasAndLengthsParameters", "esri/layers/FeatureLayer", "esri/tasks/query", "dijit/form/TextBox", "dijit/form/Button", "dijit/form/CheckBox", "gotemb/ClassifyWidget/Grid", "dijit/form/DropDownButton", "dijit/TooltipDialog"], function(declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, _arg, Dialog, SignatureClassRow, signatureFileParser, color, Polygon, ArcGISImageServiceLayer, RasterFunction, ImageServiceParameters, GeometryService, ProjectParameters, AreasAndLengthsParameters, FeatureLayer, Query) {
  var connect, extentToPolygon, showError;
  connect = _arg.connect;
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
    polygon = new Polygon(extent.spatialReference);
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
    customizeClassesButton: null,
    state: {},
    constructor: function() {
      var _this = this;
      return this.watch("map", function(attr, oldMap, newMap) {
        return connect(newMap, "onExtentChange", _this.refresh.bind(_this));
      });
    },
    postCreate: function() {
      var _this = this;
      this.signaturesGrid.set("columns", {
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
      this.classificationEnabledInput.watch("checked", function(attr, oldValue, newValue) {
        return _this.clipToSignaturePolygonsInput.set("disabled", !newValue);
      });
      return this.clipToSignaturePolygonsInput.watch("disabled", function(attr, oldValue, newValue) {
        if (newValue === true) {
          return _this.clipToSignaturePolygonsInput.set("checked", false);
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
      this.imageServiceLayer = new ArcGISImageServiceLayer(this.state.imageServiceUrl, options);
      connect(this.imageServiceLayer, "onLoad", function() {
        _this.map.addLayer(_this.imageServiceLayer);
        return typeof callback === "function" ? callback() : void 0;
      });
      return connect(this.imageServiceLayer, "onError", function(error) {
        showError("ImageServiceLayer: " + error.message);
        return delete _this.imageServiceLayer;
      });
    },
    setImageOrModifyRenderingRule: function(renderingRule) {
      var _this = this;
      if (renderingRule == null) {
        renderingRule = new RasterFunction;
      }
      if (this.imageServiceLayer == null) {
        return this.setImageLayer((function() {
          if (renderingRule == null) {
            return null;
          }
          return {
            imageServiceParameters: extend(new ImageServiceParameters, {
              renderingRule: renderingRule
            })
          };
        })(), function() {
          var geometryService;
          geometryService = new GeometryService(_this.state.geometryServiceUrl);
          connect(geometryService, "onError", function(error) {
            return showError("GeometryService: " + error.message);
          });
          return geometryService.project(extend(new ProjectParameters, {
            geometries: [_this.imageServiceLayer.fullExtent, _this.imageServiceLayer.initialExtent],
            outSR: _this.map.extent.spatialReference
          }), function(_arg1) {
            var fullExtent, initialExtent;
            fullExtent = _arg1[0], initialExtent = _arg1[1];
            _this.map.setExtent(initialExtent);
            return _this.state.imageServiceExtent = fullExtent;
          });
        });
      } else {
        return this.imageServiceLayer.setRenderingRule(renderingRule);
      }
    },
    refresh: function(force, callback) {
      var geometryService,
        _this = this;
      if (force == null) {
        force = false;
      }
      if (this.state.imageServiceUrl == null) {
        return typeof callback === "function" ? callback() : void 0;
      }
      if (!this.state.classificationEnabled) {
        if ((this.imageServiceLayer == null) || (this.imageServiceLayer.renderingRule != null)) {
          this.setImageOrModifyRenderingRule();
        }
        return typeof callback === "function" ? callback() : void 0;
      } else {
        if (this.state.featureGeos == null) {
          return;
        }
        geometryService = new GeometryService(this.state.geometryServiceUrl);
        connect(geometryService, "onError", function(error) {
          return showError("GeometryService: " + error.message);
        });
        return geometryService.intersect(this.state.featureGeos, this.map.extent, function(featuresInExtent) {
          return geometryService.areasAndLengths(extend(new AreasAndLengthsParameters, {
            calculationType: "planar",
            polygons: featuresInExtent
          }), function(areasAndLengths) {
            var cls, state;
            if (_this.state.renderedFeatureIndex !== indexOfMax(areasAndLengths.areas && _this.state.clippedImageToSignaturePolygons === _this.state.clipToSignaturePolygons && force === false)) {
              _this.state.renderedFeatureIndex = indexOfMax(areasAndLengths.areas);
              state = _this.state;
              _this.setImageOrModifyRenderingRule(extend(new RasterFunction, {
                functionName: "funchain2",
                "arguments": {
                  ClippingGeometry: _this.state.clipToSignaturePolygons ? _this.state.featureGeos[_this.state.renderedFeatureIndex] : extentToPolygon(_this.state.imageServiceExtent),
                  SignatureFile: _this.state.signatures[_this.state.renderedFeatureIndex],
                  Colormap: (function() {
                    var _i, _len, _ref, _results;
                    _ref = state.signatureClasses;
                    _results = [];
                    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                      cls = _ref[_i];
                      if (cls.get("sigFile") === state.signatures[state.renderedFeatureIndex]) {
                        _results.push([cls.get("sigValue")].concat(color.fromHex(cls.get("sigColor")).toRgb()));
                      }
                    }
                    return _results;
                  })()
                },
                variableName: "Raster"
              }));
            }
            return typeof callback === "function" ? callback() : void 0;
          });
        });
      }
    },
    applyChanges: function(callback) {
      var fun1, _ref, _ref1,
        _this = this;
      if (this.map == null) {
        return showError("Widget not bound to an instance of 'Map'.");
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
      this.customizeClassesButton.set("disabled", !this.state.classificationEnabled);
      if (this.state.classificationEnabled) {
        fun1 = function() {
          var signaturesLayer;
          signaturesLayer = new FeatureLayer(_this.signaturesUrlInput.get("value"), {
            outFields: ["SIGURL"]
          });
          connect(signaturesLayer, "onLoad", function() {
            return signaturesLayer.selectFeatures(extend(new Query, {
              geometry: _this.imageServiceLayer.fullExtent,
              spatialRelationship: Query.SPATIAL_REL_INTERSECTS
            }), FeatureLayer.SELECTION_NEW, function(features) {
              var f, fun2, parsedClasses, _i, _len, _results;
              if (features.length === 0) {
                return showError("No features found within image service extent.");
              }
              fun2 = function() {
                var f, geometryService;
                _this.state.signatures = (function() {
                  var _i, _len, _results;
                  _results = [];
                  for (_i = 0, _len = features.length; _i < _len; _i++) {
                    f = features[_i];
                    _results.push(f.attributes.SIGURL);
                  }
                  return _results;
                })();
                geometryService = new GeometryService(_this.state.geometryServiceUrl);
                connect(geometryService, "onError", function(error) {
                  return showError("GeometryService: " + error.message);
                });
                return geometryService.project(extend(new ProjectParameters, {
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
                    return _this.refresh(false, callback);
                  });
                });
              };
              if (_this.state.signaturesUrl === _this.signaturesUrlInput.get("value")) {
                return fun2();
              }
              _this.state.signaturesUrl = _this.signaturesUrlInput.get("value");
              _this.classificationEnabledInput.set("disabled", false);
              _this.classificationEnabledInput.set("checked", true);
              parsedClasses = [];
              _results = [];
              for (_i = 0, _len = features.length; _i < _len; _i++) {
                f = features[_i];
                _results.push((function(f) {
                  return signatureFileParser.getClasses(f.attributes.SIGURL, function(sigClasses) {
                    var classes, cls, d, data, file, i, _j, _k, _len1, _len2, _ref2;
                    parsedClasses.push({
                      file: f.attributes.SIGURL,
                      classes: sigClasses
                    });
                    if (parsedClasses.length === features.length) {
                      data = [];
                      for (_j = 0, _len1 = parsedClasses.length; _j < _len1; _j++) {
                        _ref2 = parsedClasses[_j], file = _ref2.file, classes = _ref2.classes;
                        for (i = _k = 0, _len2 = classes.length; _k < _len2; i = ++_k) {
                          cls = classes[i];
                          data.push(d = new SignatureClassRow({
                            sigClass: cls.classname,
                            sigColor: color.fromHsv((classes.length === 1 ? 180 : i / classes.length * 360), 80, 80).toHex(),
                            sigValue: cls.value,
                            sigFile: file,
                            onColorChanged: function() {
                              return _this.refresh(true);
                            }
                          }));
                          d.startup();
                        }
                      }
                      _this.state.signatureClasses = data;
                      return fun2();
                    }
                  });
                })(f));
              }
              return _results;
            });
          });
          return connect(signaturesLayer, "onError", function(error) {
            return showError("FeatureLayer: " + error.message);
          });
        };
        if (this.imageServiceLayer != null) {
          return fun1();
        }
        return this.setImageLayer(null, function() {
          var geometryService;
          geometryService = new GeometryService(_this.state.geometryServiceUrl);
          connect(geometryService, "onError", function(error) {
            return showError("GeometryService: " + error.message);
          });
          return geometryService.project(extend(new ProjectParameters, {
            geometries: [_this.imageServiceLayer.fullExtent, _this.imageServiceLayer.initialExtent],
            outSR: _this.map.extent.spatialReference
          }), function(_arg1) {
            var fullExtent, initialExtent;
            fullExtent = _arg1[0], initialExtent = _arg1[1];
            _this.map.setExtent(initialExtent);
            _this.state.imageServiceExtent = fullExtent;
            return setTimeout(fun1, 500);
          });
        });
      } else {
        return this.refresh(false, callback);
      }
    },
    classificationEnabledInputValueChanged: function(value) {
      return this.clipToSignaturePolygonsInput.set("disabled", !value);
    },
    openSignaturesBox: function() {
      var fun1,
        _this = this;
      fun1 = function() {
        var cls, data, state;
        state = _this.state;
        data = (function() {
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
        })();
        return _this.signaturesGrid.renderArray(data);
      };
      if (this.state.classificationEnabled) {
        return fun1();
      }
      return this.applyChanges(fun1);
    },
    closeSignaturesBox: function() {
      return this.signaturesGrid.refresh();
    }
  });
});
