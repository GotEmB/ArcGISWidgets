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
	"esri/dijit/Attribution"
	"gotemb/GeorefWidget"
	"esri/dijit/Geocoder"
], (registry, ready, Map, Point) ->
	ready ->
		map = new Map "map", center: [-56.049, 38.485], zoom: 3, basemap: "satellite"
		# Using HTML5 Geolocation API
		navigator.geolocation?.getCurrentPosition ({coords}) -> map.centerAndZoom new Point(coords.longitude, coords.latitude), 8
		registry.byId("georefWidget").set "map", map
		registry.byId("geocoder").set "map", map