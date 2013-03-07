###
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
###

require [
	"dijit/registry"
	"dojo/ready"
	"dojo/dom"
	"dojox/layout/Dock"
	"dojox/layout/FloatingPane"
	"gotemb/ClassifyWidget"
	"dojo/parser"
	"dijit/layout/BorderContainer"
	"dijit/layout/ContentPane"
	"dijit/TitlePane"
	"esri/map"
	"esri/geometry"
	"esri/dijit/Attribution"
], (registry, ready, dom, Dock, FloatingPane, ClassifyWidget) ->
	ready ->
		map = new esri.Map "map", center: [-56.049, 38.485], zoom: 3, basemap: "streets"
		# Using HTML5 Geolocation API
		navigator.geolocation?.getCurrentPosition ({coords}) -> map.centerAndZoom new esri.geometry.Point(coords.longitude, coords.latitude), 8
		dock = new Dock (id: "dock"), dom.byId "dock"
		classifyWidgetContainer = new FloatingPane
			title: "Classify Widget"
			resizable: false
			dockable: true
			dockTo: "dock"
			closable: false
			content: (classifyWidget = new ClassifyWidget id: "classifyWidget").domNode
		, dom.byId "classifyWidgetContainer"
		classifyWidgetContainer.startup()
		classifyWidget.set "map", map
