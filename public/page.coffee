###
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
###

require [
	"dijit/registry"
	"dojo/ready"
	"esri/map"
	"esri/geometry/Point"
	"dojo/parser"
	"dijit/layout/BorderContainer"
	"dijit/layout/ContentPane"
	"dijit/TitlePane"
	"esri/dijit/Attribution"
	"gotemb/ClassifyWidget"
], (registry, ready, Map, Point) ->
	ready ->
		map = new Map "map", center: [-56.049, 38.485], zoom: 3, basemap: "streets"
		# Using HTML5 Geolocation API
		navigator.geolocation?.getCurrentPosition ({coords}) -> map.centerAndZoom new Point(coords.longitude, coords.latitude), 8
		registry.byId("classifyWidget").set "map", map