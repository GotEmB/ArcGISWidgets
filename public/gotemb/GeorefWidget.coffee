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
	"esri/layers/GraphicsLayer"
	"dojo/_base/Color"
	"esri/symbols/SimpleMarkerSymbol"
	"esri/symbols/SimpleLineSymbol"
	"esri/graphic"
	"esri/geometry/Point"
	"dojo/window"
	"dojo/dom-class"
	"dojo/query"
	# ---
	"dojox/form/FileInput"
	"dijit/form/Button"
	"dijit/form/DropDownButton"
	"dijit/layout/AccordionContainer"
	"dijit/layout/ContentPane"
	"gotemb/GeorefWidget/RastersGrid"
	"dijit/Dialog"
	"dijit/Toolbar"
	"dijit/ToolbarSeparator"
	"dijit/form/ToggleButton"
	"dijit/Menu"
	"dijit/MenuItem"
	"dijit/CheckedMenuItem"
	"dojo/NodeList-traverse"
	"dojo/NodeList-dom"
], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, {connect}, ArcGISImageServiceLayer, request, MosaicRule, Polygon, GeometryService, domStyle, PointGrid, Observable, Memory, TiepointsGrid, GraphicsLayer, Color, SimpleMarkerSymbol, SimpleLineSymbol, Graphic, Point, win, domClass, query) ->
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
		tasksContainer: null
		editTiepointsContainer: null
		editTiepointsContainer_loading: null
		tiepoints: null
		tiepointsGrid: null
		toggleTiepointsSelectionButton: null
		tiepointsLayer: null
		rasters_toggleReferenceLayersButton: null
		editTiepoints_toggleReferenceLayerButton: null
		editTiepoints_toggleRasterLayerButton: null
		tiepointsContextMenu: null
		resetTiepointMenuItem: null
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
				@loadRastersList()
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
							domStyle.set @tasksContainer.domNode, "display", "block"
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
							pointGrid = new PointGrid
								x: value.geometry.x
								y: value.geometry.y
								onPointChanged: ({x, y}) =>
									point = new Point value.geometry
									point.x = x
									point.y = y
									value.setGeometry point
							value.pointChanged = =>
								pointGrid.setPoint x: value.geometry.x, y: value.geometry.y
							value.gotoPointGrid = =>
								win.scrollIntoView pointGrid.domNode
								tdId = new query.NodeList(pointGrid.domNode).parent().parent().children().first()
								tdId.removeClass "yellow"
								setTimeout (=> tdId.addClass "yellow"), 0
							pointGrid.domNode
					,
						label: "Target Point"
						field: "targetPoint"
						sortable: false
						renderCell: (object, value, domNode) =>
							pointGrid = new PointGrid
								x: value.geometry.x
								y: value.geometry.y
								onPointChanged: ({x, y}) =>
									point = new Point value.geometry
									point.x = x
									point.y = y
									value.setGeometry point
							value.pointChanged = =>
								pointGrid.setPoint x: value.geometry.x, y: value.geometry.y
							value.gotoPointGrid = =>
								win.scrollIntoView pointGrid.domNode
								tdId = new query.NodeList(pointGrid.domNode).parent().parent().children().first()
								tdId.removeClass "yellow"
								setTimeout (=> tdId.addClass "yellow"), 0
							pointGrid.domNode
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
					for row in rows
						row.data.sourcePoint.show()
						row.data.targetPoint.show()
				@tiepointsGrid.on "dgrid-deselect", ({rows}) =>
					for rowId, bool of @tiepointsGrid.selection when bool
						noneSelected = false
					@toggleTiepointsSelectionButton.set "label", "Select All" unless noneSelected? and not noneSelected	
					for row in rows
						row.data.sourcePoint.hide()
						row.data.targetPoint.hide()
				@tiepointsLayer = new GraphicsLayer
				@map.addLayer @tiepointsLayer
				connect @tiepointsLayer, "onMouseDown", (e) =>
					@map.disablePan()
					@graphicBeingMoved = e.graphic
					@graphicBeingMoved.gotoPointGrid()
				connect @tiepointsLayer, "onClick onDblClick", (e) =>
					delete @graphicBeingMoved
					@map.enablePan()
				connect @map, "onMouseDrag", (e) =>
					return unless @graphicBeingMoved?
					@graphicBeingMoved.setGeometry e.mapPoint
					@graphicBeingMoved.pointChanged()
				connect @map, "onMouseDragEnd", (e) =>
					return unless @graphicBeingMoved?
					@graphicBeingMoved.setGeometry e.mapPoint
					@graphicBeingMoved.pointChanged()
					delete @graphicBeingMoved
					@map.enablePan()
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
				url: "dummyResponses/tiepoints1.json" # @imageServiceUrl + "/computeTiePoints"
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
				# (usePost: true)
		toggleReferenceLayer: (state) ->
			@referenceLayer.setOpacity if state then 1 else 0
			@rasters_toggleReferenceLayersButton.set "checked", state
			@editTiepoints_toggleReferenceLayerButton.set "checked", state
		toggleRasterLayer: (state) ->
			@imageServiceLayer.setOpacity if state then 1 else 0
		startEditTiepoints: ->
			domStyle.set @editTiepointsContainer_loading, "display", "block"
			for display, containers of {none: [@selectRasterContainer, @tasksContainer], block: [@editTiepointsContainer]}
				domStyle.set container.domNode, "display", display for container in containers
			@computeTiePoints ({tiePoints}) =>
				domStyle.set @editTiepointsContainer_loading, "display", "none"
				sourceSymbol =
					new SimpleMarkerSymbol(
						SimpleMarkerSymbol.STYLE_X
						10
						new SimpleLineSymbol(
							SimpleLineSymbol.STYLE_SOLID
							new Color([20, 20, 180])
							2
						)
						new Color [0, 0, 0]
					)
				targetSymbol =
					new SimpleMarkerSymbol(
						SimpleMarkerSymbol.STYLE_X
						10
						new SimpleLineSymbol(
							SimpleLineSymbol.STYLE_SOLID
							new Color([180, 20, 20])
							2
						)
						new Color [0, 0, 0]
					)
				for i in [0...tiePoints.sourcePoints.length]
					@tiepoints.put
						id: i + 1
						sourcePoint: sourcePoint = new Graphic new Point(tiePoints.sourcePoints[i]), sourceSymbol
						targetPoint: targetPoint = new Graphic new Point(tiePoints.targetPoints[i]), targetSymbol
						original:
							sourcePoint: new Point tiePoints.sourcePoints[i]
							targetPoint: new Point tiePoints.targetPoints[i]
					@tiepointsLayer.add sourcePoint
					@tiepointsLayer.add targetPoint
				@tiepointsGrid.selectAll()
		closeEditTiepoints: ->
			domStyle.set @editTiepointsContainer_loading, "display", "none"
			@tiepointsLayer.clear()
			@tiepoints.remove tiepoint.id for tiepoint in @tiepoints.data.splice 0
			for display, containers of {block: [@selectRasterContainer, @tasksContainer], none: [@editTiepointsContainer]}
				domStyle.set container.domNode, "display", display for container in containers
		toggleTiepointsSelection: ->
			if @toggleTiepointsSelectionButton.label is "Clear Selection"
				@tiepointsGrid.clearSelection()
			else
				@tiepointsGrid.selectAll()
		tiepointsContextMenuOpen: ->
			domStyle.set @resetTiepointMenuItem.domNode, "display", if @tiepointsGrid.cell(@tiepointsContextMenu.currentTarget).row.data.original? then "table-row" else "none"
		removeTiepoint: ->
			@tiepoints.remove (tiepoint = @tiepointsGrid.cell(@tiepointsContextMenu.currentTarget).row.data).id
			@tiepointsLayer.remove graphic for graphic in [tiepoint.sourcePoint, tiepoint.targetPoint]
		resetTiepoint: ->
			tiepoint = @tiepointsGrid.cell(@tiepointsContextMenu.currentTarget).row.data
			for key in ["sourcePoint", "targetPoint"]
				tiepoint[key].setGeometry tiepoint.original[key]
				tiepoint[key].pointChanged()