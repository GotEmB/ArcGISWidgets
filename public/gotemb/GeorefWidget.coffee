# Extend `obj` with `mixin`
extend = (obj, mixin) ->
	obj[name] = method for name, method of mixin        
	obj

define [
	"dojo/_base/declare"
	"dijit/_WidgetBase"
	"dijit/_TemplatedMixin"
	"dijit/_WidgetsInTemplateMixin"
	"dojo/text!./GeorefWidget/templates/GeorefWidget.html"
	"dojo/_base/connect"
	"esri/layers/ArcGISImageServiceLayer"
	"esri/request"
	"esri/layers/MosaicRule"
	"esri/geometry/Polygon"
	"esri/tasks/GeometryService"
	"dojo/dom-style"
	"gotemb/GeorefWidget/PointGrid"
	"dojo/store/Observable"
	"dojo/store/Memory"
	"gotemb/GeorefWidget/TiepointsGrid"
	# ---
	"dojox/form/FileInput"
	"dijit/form/Button"
	"dijit/layout/AccordionContainer"
	"dijit/layout/ContentPane"
	"gotemb/GeorefWidget/RastersGrid"
	"dijit/Dialog"
	"dijit/Toolbar"
	"dijit/ToolbarSeparator"
	"dijit/form/ToggleButton"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, {connect}, ArcGISImageServiceLayer, request, MosaicRule, Polygon, GeometryService, domStyle, PointGrid, Observable, Memory, TiepointsGrid) ->
	declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
		templateString: template
		baseClass: "ClassifyWidget"
		map: null # should be bound to a `Map` instance before using the widget
		imageFile: null
		uploadForm: null
		imageServiceUrl: "http://eg1109:6080/arcgis/rest/services/amberg_wgs/ImageServer"
		imageServiceLayer: null
		referenceLayerUrl: "http://eg1109:6080/arcgis/rest/services/amberg_wgs_reference/ImageServer"
		referenceLayer: null
		geometryServiceUrl: "http://lamborghini:6080/arcgis/rest/services/Utilities/Geometry/GeometryServer"
		geometryService: null
		rastertype: null
		currentId: null
		rasters: null
		rastersGrid: null
		addRasterDialog: null
		selectRasterContainer: null
		transformContainer: null
		editTiepointsContainer: null
		editTiepointsContainer_loading: null
		tiepoints: null
		tiepointsGrid: null
		toggleTiepointsSelectionButton: null
		postCreate: ->
			@imageServiceLayer = new ArcGISImageServiceLayer @imageServiceUrl
			@geometryService = new GeometryService @geometryServiceUrl
			connect @imageServiceLayer, "onLoad", =>
				@map.addLayer @referenceLayer = new ArcGISImageServiceLayer @referenceLayerUrl
				@imageServiceLayer.setOpacity 0
				@map.addLayer @imageServiceLayer
				@rastersGrid.set "columns", [
					label: "Raster Id"
					field: "rasterId"
					sortable: false
				,
					label: "Name"
					field: "name"
					sortable: false
				]
				@rastersGrid.set "selectionMode", "single"
				@loadRastersList =>
					@rastersGrid.on "dgrid-select", ({rows}) =>
						return if @currentId is rows[0].data.rasterId
						@currentId = rows[0].data.rasterId
						@imageServiceLayer.setMosaicRule extend(
							new MosaicRule
							method: MosaicRule.METHOD_LOCKRASTER
							lockRasterIds: [@currentId]
						), true
						request
							url: @imageServiceUrl + "/query"
							content:
								objectIds: [@currentId]
								returnGeometry: true
								outFields: ""
								f: "json"
							handleAs: "json"
							load: (response3) =>
								@map.setExtent new Polygon(response3.features[0].geometry).getExtent().expand 2
								@imageServiceLayer.setOpacity 1
							error: console.error
							(usePost: true)
				@tiepoints = new Observable new Memory idProperty: "id"
				@tiepointsGrid = new TiepointsGrid
					columns: [
						label: " "
						field: "id"
						sortable: false
					,
						label: "Source Point"
						field: "sourcePoint"
						sortable: false
						renderCell: (object, value, domNode) =>
							new PointGrid
								x: value.x
								y: value.y
								onPointChanged: ({x, y}) =>
									value.x = x
									value.y = y
							.domNode
					,
						label: "Target Point"
						field: "targetPoint"
						sortable: false
						renderCell: (object, value, domNode) =>
							new PointGrid
								x: value.x
								y: value.y
								onPointChanged: ({x, y}) =>
									value.x = x
									value.y = y
							.domNode
					]
					store: @tiepoints
					selectionMode: "none"
					@tiepointsGrid
				@tiepointsGrid.startup()
				@tiepointsGrid.on ".field-id:click", (e) =>
					if @tiepointsGrid.isSelected row = @tiepointsGrid.cell(e).row
						@tiepointsGrid.deselect row
					else
						@tiepointsGrid.select row
				@tiepointsGrid.on "dgrid-select", ({rows}) =>
					@toggleTiepointsSelectionButton.set "label", "Clear Selection"
				@tiepointsGrid.on "dgrid-deselect", ({rows}) =>
					for rowId, bool of @tiepointsGrid.selection when bool
						noneSelected = false
					@toggleTiepointsSelectionButton.set "label", "Select All" unless noneSelected? and not noneSelected
		loadRastersList: (callback) ->
			request
				url: @imageServiceUrl + "/query"
				content:
					f: "json"
					outFields: "OBJECTID, Name"
				handlesAs: "json"
				load: (response) =>
					@rasters =
						for feature in response.features
							rasterId: feature.attributes.OBJECTID
							name: feature.attributes.Name
							spatialReference: feature.geometry.spatialReference
					@rastersGrid.refresh()
					@rastersGrid.renderArray @rasters
					callback?()
				error: console.error
				(usePost: true)
		showAddRasterDialog: ->
			@addRasterDialog.show()
		addRasterDialog_upload: ->
			return console.error "An image must be selected!" if @imageFile.value.length is 0
			@rastertype = if @imageFile.value.indexOf("las") is -1 then "Raster Dataset" else "HillshadedLAS"
			console.info "Step 1/3: Uploading..."
			request
				url: @imageServiceUrl + "/uploads/upload"
				form: @uploadForm
				content: f: "json"
				handleAs: "json"
				timeout: 600000
				load: (response1) =>
					return console.error "Unsuccessful upload:\n#{response1}" unless response1.success
					console.info "Step 2/3: Uploaded, processing the image on server side..."
					request
						url: @imageServiceUrl + "/add"
						content:
							itemIds: response1.item.itemID
							rasterType: @rastertype
							minimumCellSizeFactor: 0.1
							maximumCellSizeFactor: 10
							f: "json"
						handleAs: "json"
						load: (response2) =>
							if id = response2.addResults[0].rasterId
								@loadRastersList =>
									@addRasterDialog.hide()
									@rastersGrid.clearSelection()
									@rastersGrid.select @rasters.length - 1 if @rasters.length > 0
						error: console.error
						(usePost: true)
				error: console.error
				(usePost: true)
		roughTransform: ->
			return console.error "No raster selected" unless @currentId?
			request
				url: @imageServiceUrl + "/#{@currentId}/info"
				content: f: "json"
				handleAs: "json"
				load: (response1) =>
					src = response1.extent
					request
						url: @imageServiceUrl + "/update"
						content:
							f: "json"
							rasterId: @currentId
							geodataTransforms: JSON.stringify [
								geodataTransform: "Polynomial"
								geodataTransformArguments:
									sourcePoints: [
										{x: src.xmin, y: src.ymin}
										{x: src.xmin, y: src.ymax}
										{x: src.xmax, y: src.ymin}
									]
									targetPoints: do =>
										aspectRatio = (src.xmax - src.xmin) / (src.ymax - src.ymin)
										map =
											width: @map.extent.getWidth()
											height: @map.extent.getHeight()
											center: @map.extent.getCenter().toJson()
										dest =
											width: Math.min map.width, map.height * aspectRatio
											height: Math.min map.height, map.width / aspectRatio
										dest.xmin = map.center.x - dest.width / 2
										dest.xmax = map.center.x + dest.width / 2
										dest.ymin = map.center.y - dest.height / 2
										dest.ymax = map.center.y + dest.height / 2
										[
											{x: dest.xmin, y: dest.ymin}
											{x: dest.xmin, y: dest.ymax}
											{x: dest.xmax, y: dest.ymin}
										]
									polynomialOrder: 1
									spatialReference: src.spatialReference
							]
						handleAs: "json"
						load: =>
							request
								url: @imageServiceUrl + "/query"
								content:
									objectIds: @currentId
									returnGeometry: true
									outFields: ""
									f: "json"
								handleAs: "json"
								load: (response3) =>
									@map.setExtent new Polygon(response3.features[0].geometry).getExtent().expand 2
								error: console.error
								(usePost: true)
						error: console.error
						(usePost: true)
				error: console.error
				(usePost: true)
		computeAndTransform: ->
			@computeTiePoints ({tiePoints}) =>
				request
					url: @imageServiceUrl + "/update"
					content:
						f: "json"
						rasterId: @currentId
						geodataTransforms: JSON.stringify [
							geodataTransform: "Polynomial"
							geodataTransformArguments:
								sourcePoints: x: point.x, y: point.y for point in tiePoints.sourcePoints
								targetPoints: x: point.x, y: point.y for point in tiePoints.targetPoints
								polynomialOrder: 1
								spatialReference: tiePoints.sourcePoints[0].spatialReference
						]
					handleAs: "json"
					load: =>
						request
							url: @imageServiceUrl + "/query"
							content:
								objectIds: @currentId
								returnGeometry: true
								outFields: ""
								f: "json"
							handleAs: "json"
							load: (response2) =>
								@map.setExtent new Polygon(response2.features[0].geometry).getExtent().expand 2
							error: console.error
					error: console.error
					(usePost: true)
		computeTiePoints: (callback) ->
			return console.error "No raster selected" unless @currentId?
			request
				url: "dummyResponses/tiepoints1.json" #@imageServiceUrl + "/computeTiePoints"
				content:
					f: "json"
					rasterId: @currentId
					geodataTransforms: JSON.stringify [
						geodataTransform: "Identity"
						geodataTransformArguments:
							spatialReference: @rasters.filter((x) => x.rasterId is @currentId)[0].spatialReference
					]
				handleAs: "json"
				load: (response) ->
					callback? response
				error: console.error
				#(usePost: true)
		toggleReferenceLayer: (state) ->
			@referenceLayer.setOpacity if state then 1 else 0
		startEditTiepoints: ->
			domStyle.set @editTiepointsContainer_loading, "display", "block"
			for display, containers of {none: [@selectRasterContainer, @transformContainer], block: [@editTiepointsContainer]}
				domStyle.set container.domNode, "display", display for container in containers
			@computeTiePoints ({tiePoints}) =>
				domStyle.set @editTiepointsContainer_loading, "display", "none"
				for i in [0...tiePoints.sourcePoints.length]
					@tiepoints.put
						id: i + 1
						sourcePoint:
							x: tiePoints.sourcePoints[i].x
							y: tiePoints.sourcePoints[i].y
						targetPoint:
							x: tiePoints.targetPoints[i].x
							y: tiePoints.targetPoints[i].y
					@tiepointsGrid.selectAll()
		closeEditTiepoints: ->
			domStyle.set @editTiepointsContainer_loading, "display", "none"
			for display, containers of {block: [@selectRasterContainer, @transformContainer], none: [@editTiepointsContainer]}
				domStyle.set container.domNode, "display", display for container in containers
		toggleTiepointsSelection: ->
			if @toggleTiepointsSelectionButton.label is "Clear Selection"
				@tiepointsGrid.clearSelection()
			else
				@tiepointsGrid.selectAll()