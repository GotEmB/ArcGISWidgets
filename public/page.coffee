require [
	"dijit/registry"
	"dojo/ready"
	"dojo/dom"
	"dojox/layout/FloatingPane"
	"gotemb/ClassifyWidget"
	"dojo/parser"
	"dijit/layout/BorderContainer"
	"dijit/layout/ContentPane"
	"dijit/TitlePane"
	"esri/map"
	"esri/geometry"
	"esri/dijit/Attribution"
], (registry, ready, dom, FloatingPane, ClassifyWidget) ->
	ready ->
		map = new esri.Map "map", center: [-56.049, 38.485], zoom: 3, basemap: "streets"
		navigator.geolocation?.getCurrentPosition ({coords}) -> map.centerAndZoom new esri.geometry.Point(coords.longitude, coords.latitude), 8
		classifyWidget = new ClassifyWidget
		classifyWidgetContainer = new FloatingPane
			title: "Classify Widget"
			resizable: false
			dockable: false
			closable: false
			id: "classifyWidgetContainer"
			style: "height: 160px; width: 390px"
			content: classifyWidget.domNode
		, dom.byId "classifyWidgetContainer"
		classifyWidgetContainer.startup()
		classifyWidget.set "map", map