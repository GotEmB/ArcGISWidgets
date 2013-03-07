###
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
###

require [
	"dijit/registry"
	"dojo/ready"
	"dojo/parser"
	"dijit/layout/BorderContainer"
	"dijit/layout/ContentPane"
	"dijit/TitlePane"
	"esri/map"
	"esri/geometry"
	"esri/dijit/Attribution"
	"gotemb/ClassifyWidget"
], (registry, ready) ->
	ready ->
		map = new esri.Map "map", center: [-56.049, 38.485], zoom: 3, basemap: "streets"
		# Using HTML5 Geolocation API
		navigator.geolocation?.getCurrentPosition ({coords}) -> map.centerAndZoom new esri.geometry.Point(coords.longitude, coords.latitude), 8
		registry.byId("classifyWidget").set "map", map