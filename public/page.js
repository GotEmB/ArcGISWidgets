// Generated by CoffeeScript 1.4.0
/*
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
*/

require(["dijit/registry", "dojo/ready", "dojo/dom", "dojox/layout/Dock", "dojox/layout/FloatingPane", "gotemb/ClassifyWidget", "dojo/parser", "dijit/layout/BorderContainer", "dijit/layout/ContentPane", "dijit/TitlePane", "esri/map", "esri/geometry", "esri/dijit/Attribution"], function(registry, ready, dom, Dock, FloatingPane, ClassifyWidget) {
  return ready(function() {
    var classifyWidget, classifyWidgetContainer, dock, map, _ref;
    map = new esri.Map("map", {
      center: [-56.049, 38.485],
      zoom: 3,
      basemap: "streets"
    });
    if ((_ref = navigator.geolocation) != null) {
      _ref.getCurrentPosition(function(_arg) {
        var coords;
        coords = _arg.coords;
        return map.centerAndZoom(new esri.geometry.Point(coords.longitude, coords.latitude), 8);
      });
    }
    dock = new Dock({
      id: "dock"
    }, dom.byId("dock"));
    classifyWidgetContainer = new FloatingPane({
      title: "Classify Widget",
      resizable: false,
      dockable: true,
      dockTo: "dock",
      closable: false,
      content: (classifyWidget = new ClassifyWidget({
        id: "classifyWidget"
      })).domNode
    }, dom.byId("classifyWidgetContainer"));
    classifyWidgetContainer.startup();
    return classifyWidget.set("map", map);
  });
});
