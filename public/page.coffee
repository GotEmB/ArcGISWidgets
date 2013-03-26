###
# Author: Gautham Badhrinathan (gbadhrinathan@esri.com)
###

geometryServiceUrl = "http://lamborghini:6080/arcgis/rest/services/Utilities/Geometry/GeometryServer"
imageServiceUrl = "http://lamborghini:6080/arcgis/rest/services/Reproj_Clip_p033r032_7dt20020920_z13_MS1/ImageServer"
featureServiceUrl = "http://lamborghini:6080/arcgis/rest/services/Signatures/MapServer/0"

require [
	"dojo/ready"
	"esri/geometry"
	"esri/layers/FeatureLayer"
], (ready) ->
	ready ->
		featureLayer = new esri.layers.FeatureLayer featureServiceUrl, outFields: ["SIGURL"]
		dojo.connect featureLayer, "onLoad", =>
			query = new esri.tasks.Query
			query.geometry = featureLayer.fullExtent
			query.spatialRelationship = esri.tasks.Query.SPATIAL_REL_INTERSECTS
			featureLayer.selectFeatures query, esri.layers.FeatureLayer.SELECTION_NEW, (features) =>
				console.log features