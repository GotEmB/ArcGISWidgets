do ->
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
		"dgrid/editor"
		"gotemb/GeorefWidget/RastersGrid"
		"esri/geometry/Extent"
		"esri/tasks/ProjectParameters"
		"esri/SpatialReference"
		"dojo/_base/url"
		"esri/layers/ArcGISTiledMapServiceLayer"
		"gotemb/GeorefWidget/AsyncResultsGrid"
		"dijit/popup"
		"dijit/form/CheckBox"
		"dojo/aspect"
		# ---
		"dojox/form/FileInput"
		"dijit/form/Button"
		"dijit/form/DropDownButton"
		"dijit/layout/AccordionContainer"
		"dijit/layout/ContentPane"
		"dijit/Dialog"
		"dijit/Toolbar"
		"dijit/ToolbarSeparator"
		"dijit/form/ToggleButton"
		"dijit/Menu"
		"dijit/MenuItem"
		"dijit/CheckedMenuItem"
		"dojo/NodeList-traverse"
		"dojo/NodeList-dom"
		"dijit/TooltipDialog"
	], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, {connect, disconnect}, ArcGISImageServiceLayer, request, MosaicRule, Polygon, GeometryService, domStyle, PointGrid, Observable, Memory, TiepointsGrid, GraphicsLayer, Color, SimpleMarkerSymbol, SimpleLineSymbol, Graphic, Point, win, domClass, query, editor, RastersGrid, Extent, ProjectParameters, SpatialReference, Url, ArcGISTiledMapServiceLayer, AsyncResultsGrid, popup, CheckBox, aspect) ->
		declare [_WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin],
			templateString: template
			baseClass: "GeorefWidget"
			map: null # should be bound to a `Map` instance before using the widget
			imageFile: null
			uploadForm: null
			imageServiceUrl: "http://eg1109.uae.esri.com:6080/arcgis/rest/services/ISERV/ImageServer"
			imageServiceLayer: null
			geometryServiceUrl: "http://tasks.arcgisonline.com/arcgis/rest/services/Geometry/GeometryServer"
			geometryService: null
			rastertype: null
			currentId: null
			rasters: null
			rastersGrid: null
			addRasterDialog: null
			selectRasterContainer: null
			tasksContainer: null
			editTiepointsContainer: null
			tiepoints: null
			tiepointsGrid: null
			toggleTiepointsSelectionMenuItem: null
			tiepointsLayer: null
			tiepointsContextMenu: null
			resetTiepointMenuItem: null
			mouseTip: null
			addTiepointButton: null
			removeSelectedTiepointsMenuItem: null
			resetSelectedTiepointsMenuItem: null
			manualTransformContainer: null
			rtMoveContainer: null
			rtMoveFromGrid: null
			rtMoveToGrid: null
			rt_moveButton: null
			rt_scaleButton: null
			rt_rotateButton: null
			rtMoveFromPickButton: null
			rtMoveToPickButton: null
			miscGraphicsLayer: null
			rtScaleContainer: null
			rtScaleFactorInput: null
			rtRotateContainer: null
			rtRotateDegreesInput: null
			rasterNotSelectedDialog: null
			selectBasemap_SatelliteButton: null
			selectBasemap_HybridButton: null
			selectBasemap_TopographicButton: null
			selectBasemap_StreetsButton: null
			selectBasemap_NaturalVueButton: null
			naturalVueServiceUrl: "http://raster.arcgisonline.com/ArcGIS/rest/services/MDA_NaturalVue_Imagery_cached/MapServer"
			naturalVueServiceLayer: null
			asyncResultsContainer: null
			asyncResults: null
			asyncResultsGrid: null
			asyncTaskDetailsPopup: null
			atdpResultId: null
			atdpTask: null
			atdpRasterId: null
			atdpStatus: null
			atdpStartTime: null
			atdpEndTime: null
			atdpContinueButton: null
			sourceSymbol:
				new SimpleMarkerSymbol(
					SimpleMarkerSymbol.STYLE_X
					10
					new SimpleLineSymbol(
						SimpleLineSymbol.STYLE_SOLID
						new Color [20, 20, 180]
						2
					)
					new Color [0, 0, 0]
				)
			targetSymbol:
				new SimpleMarkerSymbol(
					SimpleMarkerSymbol.STYLE_X
					10
					new SimpleLineSymbol(
						SimpleLineSymbol.STYLE_SOLID
						new Color [180, 20, 20]
						2
					)
					new Color [0, 0, 0]
				)
			selectedSourceSymbol:
				new SimpleMarkerSymbol(
					SimpleMarkerSymbol.STYLE_X
					16
					new SimpleLineSymbol(
						SimpleLineSymbol.STYLE_SOLID
						new Color [20, 20, 180]
						3
					)
					new Color [0, 0, 0]
				)
			selectedTargetSymbol:
				new SimpleMarkerSymbol(
					SimpleMarkerSymbol.STYLE_X
					16
					new SimpleLineSymbol(
						SimpleLineSymbol.STYLE_SOLID
						new Color [180, 20, 20]
						3
					)
					new Color [0, 0, 0]
				)
			postCreate: ->
				imageServiceAuthority = new Url(@imageServiceUrl).authority
				corsEnabledServers = esri.config.defaults.io.corsEnabledServers
				corsEnabledServers.push imageServiceAuthority unless corsEnabledServers.some (x) => x is imageServiceAuthority
				@imageServiceLayer = new ArcGISImageServiceLayer @imageServiceUrl
				@geometryService = new GeometryService @geometryServiceUrl
				onceDone = false
				@watch "map", (attr, oldMap, newMap) =>
					if onceDone then return else onceDone = true
					@map.addLayer @imageServiceLayer
					@rasters = new Observable new Memory idProperty: "rasterId"
					@rastersGrid = new RastersGrid
						columns: [
							editor
								label: " "
								field: "display"
								editor: CheckBox
						,	
							label: "Id"
							field: "rasterId"
							sortable: false
						,
							label: "Name"
							field: "name"
							sortable: false
						]
						store: @rasters
						selectionMode: "none"
						@rastersGrid
					@rastersGrid.startup()
					domStyle.set @selectRasterContainer.domNode, "display", "block"
					@loadRastersList =>
						@refreshMosaicRule()
					@rastersGrid.on ".field-rasterId:click, .field-name:click", (e) =>
						@rastersGrid.clearSelection()
						@rastersGrid.select @rastersGrid.cell(e).row
					@rastersGrid.on "dgrid-select", ({rows}) =>
						return if @currentId is rows[0].data.rasterId
						@currentId = rows[0].data.rasterId
						request
							url: @imageServiceUrl + "/query"
							content:
								objectIds: [@currentId]
								returnGeometry: true
								outFields: ""
								f: "json"
							handleAs: "json"
							load: (response3) =>
								@map.setExtent new Polygon(response3.features[0].geometry).getExtent()
							error: ({message}) => console.error message
							(usePost: true)
					@rastersGrid.on "dgrid-datachange", ({cell, value}) =>
						cell.row.data.display = value
						@refreshMosaicRule()
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
									tdId.addClass "yellow"
									mouseUpEvent = connect @tiepointsLayer, "onMouseUp", =>
										tdId.removeClass "yellow"
										disconnect mouseUpEvent
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
									tdId.addClass "yellow"
									mouseUpEvent = connect @tiepointsLayer, "onMouseUp", =>
										tdId.removeClass "yellow"
										disconnect mouseUpEvent
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
						@toggleTiepointsSelectionMenuItem.set "label", "Clear Selection"
						domStyle.set @removeSelectedTiepointsMenuItem.domNode, "display", "table-row"
						for row in rows
							domStyle.set @resetSelectedTiepointsMenuItem.domNode, "display", "table-row" if row.data.original?
							row.data.sourcePoint.setSymbol @selectedSourceSymbol
							row.data.targetPoint.setSymbol @selectedTargetSymbol
					@tiepointsGrid.on "dgrid-deselect", ({rows}) =>
						for rowId, bool of @tiepointsGrid.selection when bool
							noneSelected = false
							showReset = true if @tiepointsGrid.row(rowId).data.original?
						unless noneSelected? and not noneSelected
							@toggleTiepointsSelectionMenuItem.set "label", "Select All"
							domStyle.set @removeSelectedTiepointsMenuItem.domNode, "display", "none"
						domStyle.set @resetSelectedTiepointsMenuItem.domNode, "display", "none" unless showReset
						for row in rows
							row.data.sourcePoint.setSymbol @sourceSymbol
							row.data.targetPoint.setSymbol @targetSymbol
					@tiepointsLayer = new GraphicsLayer
					@map.addLayer @tiepointsLayer
					@miscGraphicsLayer = new GraphicsLayer
					@map.addLayer @miscGraphicsLayer
					connect @tiepointsLayer, "onMouseDown", (e) =>
						@map.disablePan()
						@graphicBeingMoved = e.graphic
						@graphicBeingMoved.gotoPointGrid()
					connect @tiepointsLayer, "onClick onDblClick", (e) =>
						delete @graphicBeingMoved
						@map.enablePan()
					connect @miscGraphicsLayer, "onMouseDown", (e) =>
						@map.disablePan()
						@graphicBeingMoved = e.graphic
					connect @miscGraphicsLayer, "onClick onDblClick", (e) =>
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
					connect @map, "onClick", (e) =>
						return unless domStyle.get(@selectRasterContainer.domNode, "display") is "block"
						rtc = (row for row in @rasters.data when row.display)
						do rec = =>
							return if rtc.length is 0
							row = rtc.pop()
							request
								url: @imageServiceUrl + "/query"
								content:
									objectIds: row.rasterId
									returnGeometry: true
									outFields: ""
									f: "json"
								handleAs: "json"
								load: (response) =>
									if new Polygon(response.features[0].geometry).contains e.mapPoint
										@rastersGrid.clearSelection()
										@rastersGrid.select row
									else
										do rec
								error: ({message}) => console.error message
								(usePost: true)
					@asyncResults = new Observable new Memory idProperty: "resultId"
					@asyncResultsGrid = new AsyncResultsGrid
						columns: [	
							label: "Id"
							field: "resultId"
							sortable: false
						,
							label: "Task"
							field: "task"
							sortable: false
						,
							label: "Status"
							field: "status"
							sortable: false
						]
						store: @asyncResults
						selectionMode: "none"
						@asyncResultsGrid
					@asyncResultsGrid.startup()
					@asyncResultsGrid.on ".field-resultId:click, .field-task:click, .field-status:click", (e) =>
						@asyncResultsGrid.clearSelection()
						@asyncResultsGrid.select @asyncResultsGrid.cell(e).row
					@asyncResultsGrid.on "dgrid-select", ({rows: [row]}) =>
						for label, value of {
							atdpResultId: "resultId"
							atdpTask: "task"
							atdpStatus: "status"
							atdpRasterId: "rasterId"
							atdpStartTime: "startTime"
							atdpEndTime: "endTime"
						}
							@[label].innerText = row.data[value] ? "--"
						domStyle.set @atdpContinueButton.domNode, "display", if row.data.callback? then "inline-block" else "none"
						@atdpContinueButton.set "label", row.data.callbackLabel ? "Continue Task"
						continueEvent = @atdpContinueButton.on "Click", =>
							continueEvent.remove()
							popup.close @asyncTaskDetailsPopup
							if row.data.rasterId?
								@rastersGrid.clearSelection()
								@rastersGrid.select @rastersGrid.row row.data.rasterId
								onceDone = false
								selectAspect = aspect.after @rastersGrid.on "dgrid-select", =>
									if onceDone then return else onceDone = true
									selectAspect.remove()
									row.data.callback?()
							else
								row.data.callback?()
						popup.open
							popup: @asyncTaskDetailsPopup
							around: row.element
							orient: ["above", "below"]
						@asyncTaskDetailsPopup.focus()
					window.self = @
			refreshMosaicRule: ->
				@imageServiceLayer.setMosaicRule extend(
					new MosaicRule
					method: MosaicRule.METHOD_LOCKRASTER
					lockRasterIds:
						if domStyle.get(@selectRasterContainer.domNode, "display") is "block" or not @currentId?
							raster.rasterId for raster in @rasters.data when raster.display
						else
							[@currentId]
				)
			loadRastersList: (callback) ->
				request
					url: @imageServiceUrl + "/query"
					content:
						f: "json"
						outFields: "OBJECTID, Name"
					handlesAs: "json"
					load: (response) =>
						for feature in response.features
							@rasters.put
								rasterId: feature.attributes.OBJECTID
								name: feature.attributes.Name
								spatialReference: new SpatialReference feature.geometry.spatialReference
								display: true
						callback?()
					error: ({message}) => console.error message; console.log esri.config.defaults.io.corsEnabledServers
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
										@rastersGrid.select @rasters.data.length - 1 if @rasters.data.length > 0
							error: ({message}) => console.error message
							(usePost: true)
					error: ({message}) => console.error message
					(usePost: true)
			computeAndTransform: ->
				return @showRasterNotSelectedDialog() unless @currentId?
				@asyncResults.put asyncTask =
					resultId: (Math.max @asyncResults.data.map((x) -> x.resultId).concat(0)...) + 1
					task: "Match raster with reference layer"
					rasterId: @currentId
					status: "Pending"
					startTime: (new Date).toLocaleString()
				domStyle.set @asyncResultsContainer.domNode, "display", "block" if domStyle.get(@selectRasterContainer.domNode, "display") is "block"
				@asyncResultsGrid.select asyncTask
				@computeTiePoints ({tiePoints, error}) =>
					extend asyncTask,
						status: if error? then "Failed" else "Completed"
						endTime: (new Date).toLocaleString()
						callback: unless error? then =>
						callbackLabel: "View Raster" unless error?
					@asyncResults.notify asyncTask, asyncTask.resultId
					@applyTransform tiePoints: tiePoints, gotoLocation: false
			applyTransform: ({tiePoints, gotoLocation}, callback) ->
				gotoLocation ?= true
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
						unless gotoLocation
							@map.setExtent @map.extent
							return callback?()
						request
							url: @imageServiceUrl + "/query"
							content:
								objectIds: @currentId
								returnGeometry: true
								outFields: ""
								f: "json"
							handleAs: "json"
							load: (response2) =>
								@map.setExtent new Polygon(response2.features[0].geometry).getExtent()
								callback?()
							error: ({message}) => console.error message
							(usePost: true)
					error: ({message}) => console.error message
					(usePost: true)
			computeTiePoints: (callback) ->
				request
					url: @imageServiceUrl + "/computeTiePoints" # "dummyResponses/tiepoints1.json"
					content:
						f: "json"
						rasterId: @currentId
						geodataTransforms: JSON.stringify [
							geodataTransform: "Identity"
							geodataTransformArguments:
								spatialReference: @rasters.data.filter((x) => x.rasterId is @currentId)[0].spatialReference
						]
					handleAs: "json"
					timeout: 600000
					load: (response) ->
						callback? response
					error: (error) =>
						console.error error.message
						callback? error: error
					(usePost: true)
			toggleRasterLayer: (state) ->
				@imageServiceLayer.setOpacity if state then 1 else 0
			startEditTiepoints: ->
				return @showRasterNotSelectedDialog() unless @currentId?
				@asyncResults.put asyncTask =
					resultId: (Math.max @asyncResults.data.map((x) -> x.resultId).concat(0)...) + 1
					task: "Compute Tiepoints"
					rasterId: @currentId
					status: "Pending"
					startTime: (new Date).toLocaleString()
				domStyle.set @asyncResultsContainer.domNode, "display", "block" if domStyle.get(@selectRasterContainer.domNode, "display") is "block"
				@asyncResultsGrid.select asyncTask
				@computeTiePoints ({tiePoints, error}) =>
					extend asyncTask,
						status: if error? then "Failed" else "Completed"
						endTime: (new Date).toLocaleString()
						callback: unless error? then =>
							for display, containers of {none: [@selectRasterContainer, @tasksContainer, @asyncResultsContainer], block: [@editTiepointsContainer]}
								domStyle.set container.domNode, "display", display for container in containers
							@refreshMosaicRule()
							for i in [0...tiePoints.sourcePoints.length]
								@tiepoints.put
									id: i + 1
									sourcePoint: sourcePoint = new Graphic new Point(tiePoints.sourcePoints[i]), @sourceSymbol
									targetPoint: targetPoint = new Graphic new Point(tiePoints.targetPoints[i]), @targetSymbol
									original:
										sourcePoint: new Point tiePoints.sourcePoints[i]
										targetPoint: new Point tiePoints.targetPoints[i]
								@tiepointsLayer.add sourcePoint
								@tiepointsLayer.add targetPoint
						callbackLabel: "Edit Tiepoints" unless error?
					@asyncResults.notify asyncTask, asyncTask.resultId
			closeEditTiepoints: ->
				@tiepointsLayer.clear()
				@tiepoints.remove tiepoint.id for tiepoint in @tiepoints.data.splice 0
				for display, containers of {block: [@selectRasterContainer, @tasksContainer], none: [@editTiepointsContainer]}
					domStyle.set container.domNode, "display", display for container in containers
				domStyle.set @asyncResultsContainer.domNode, "display", "block" if @asyncResults.data.length > 0
				@refreshMosaicRule()
			toggleTiepointsSelection: ->
				if @toggleTiepointsSelectionMenuItem.label is "Clear Selection"
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
			addTiepoint: (state) ->
				if state
					currentState = "started"
					@map.setMapCursor "crosshair"
					sourcePoint = null
					targetPoint = null
					@mouseTip.innerText = "Click to place Source Point on the map."
					mouseTipMoveEvent = connect query("body")[0], "onmousemove", (e) =>
						domStyle.set @mouseTip, "display", "block"
						domStyle.set @mouseTip, "left", e.clientX + 20 + "px"
						domStyle.set @mouseTip, "top", e.clientY + 20 + "px"
					mouseTipDownEvent = connect query("body")[0], "onmousedown", (e) =>
						return currentState = "placingSourcePoint.1" if currentState is "placingSourcePoint"
						return currentState = "placingTargetPoint.1" if currentState is "placingTargetPoint"
						closeMouseTip?()
						@tiepointsLayer.remove point for point in [sourcePoint, targetPoint]
						@addTiepointButton.set "checked", false unless @addTiepointButton.hovering
					mapDownEvent = connect @map, "onMouseDown", (e) =>
						currentState = switch currentState
							when "started" then "placingSourcePoint"
							when "placedSourcePoint" then "placingTargetPoint"
							else currentState
					mapUpEvent = connect @map, "onMouseUp", (e) =>
						if currentState is "placingSourcePoint.1"
							currentState = "placedSourcePoint"
							sourcePoint = new Graphic e.mapPoint, @sourceSymbol
							@tiepointsLayer.add sourcePoint
							@mouseTip.innerText = "Click to place Target Point on the map."
						else if currentState is "placingTargetPoint.1"
							currentState = "placedTargetPoint"
							targetPoint = new Graphic e.mapPoint, @targetSymbol
							@tiepointsLayer.add targetPoint
							@tiepoints.put tiepoint =
								id: lastId = Math.max(@tiepoints.data.map((x) => x.id).concat(0)...) + 1
								sourcePoint: sourcePoint
								targetPoint: targetPoint
							@tiepointsGrid.select tiepoint
							closeMouseTip()
							@addTiepointButton.set "checked", false
					mapDragEvent = connect @map, "onMouseDrag", (e) =>
						currentState = switch currentState
							when "placingSourcePoint.1" then "started"
							when "placingTargetPoint.1" then "placingTargetPoint"
							else currentState
					closeMouseTip = =>
						disconnect mouseTipMoveEvent
						disconnect mouseTipDownEvent
						disconnect mapDownEvent
						disconnect mapUpEvent
						disconnect mapDragEvent
						domStyle.set @mouseTip, "display", "none"
						@mouseTip.innerText = "..."
						@map.setMapCursor "default"
						currentState = "placedTiepoint"
			removeSelectedTiepoints: ->
				for rowId, bool of @tiepointsGrid.selection when bool
					@tiepoints.remove (tiepoint = @tiepointsGrid.row(rowId).data).id
					@tiepointsLayer.remove graphic for graphic in [tiepoint.sourcePoint, tiepoint.targetPoint]
			resetSelectedTiepoints: ->
				for rowId, bool of @tiepointsGrid.selection when bool
					tiepoint = @tiepointsGrid.row(rowId).data
					continue unless tiepoint.original?
					for key in ["sourcePoint", "targetPoint"]
						tiepoint[key].setGeometry tiepoint.original[key]
						tiepoint[key].pointChanged()
			applyManualTransform: ->
				for task in @asyncResults.data.filter((x) => x.rasterId is @currentId and x.task is "Compute Tiepoints")
					delete task.callback
					task.callbackLabel = "Continue Task"
				@applyTransform
					tiePoints:
						sourcePoints: @tiepoints.data.map (x) => x.sourcePoint.geometry
						targetPoints: @tiepoints.data.map (x) => x.targetPoint.geometry
					=> @closeEditTiepoints()
			openRoughTransform: ->
				return @showRasterNotSelectedDialog() unless @currentId?
				for display, containers of {none: [@selectRasterContainer, @tasksContainer, @asyncResultsContainer], block: [@manualTransformContainer]}
					domStyle.set container.domNode, "display", display for container in containers
				@refreshMosaicRule()
			closeRoughTransform: ->
				for display, containers of {block: [@selectRasterContainer, @tasksContainer], none: [@manualTransformContainer]}
					domStyle.set container.domNode, "display", display for container in containers
				domStyle.set @asyncResultsContainer.domNode, "display", "block" if @asyncResults.data.length > 0
				for button in [@rt_moveButton, @rt_scaleButton, @rt_rotateButton]
					button.set "checked", false
				@refreshMosaicRule()
			projectIfReq: ({geometries, outSR}, callback) ->
				return callback? geometries if geometries.every (x) => x.spatialReference.equals outSR
				@geometryService.project(
					extend(
						new ProjectParameters
						geometries: geometries
						outSR: outSR
					)
					(geometries) =>
						callback? geometries
				)
			rt_fit: ->
				return console.error "No raster selected" unless @currentId?
				request
					url: @imageServiceUrl + "/query"
					content:
						objectIds: @currentId
						returnGeometry: true
						outFields: ""
						f: "json"
					handleAs: "json"
					load: (response1) =>
						src = new Polygon(response1.features[0].geometry).getExtent()
						@projectIfReq
							geometries: [@map.extent]
							outSR: src.spatialReference
							([mapExtent]) =>
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
														width: mapExtent.getWidth()
														height: mapExtent.getHeight()
														center: mapExtent.getCenter()
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
												@map.setExtent new Polygon(response3.features[0].geometry).getExtent()
											error: ({message}) => console.error message
											(usePost: true)
									error: ({message}) => console.error message
									(usePost: true)
					error: ({message}) => console.error message
					(usePost: true)
			rt_move: (state) ->
				if state
					domStyle.set @rtMoveContainer.domNode, "display", "block"
					for button in [@rt_scaleButton, @rt_rotateButton]
						button.set "checked", false
					for theGrid in [@rtMoveFromGrid, @rtMoveToGrid]
						theGrid.set "onPointChanged", =>
							thePoint = new Graphic(
								new Point
									x: Number theGrid.get "x"
									y: Number theGrid.get "y"
									spatialReference: @map.spatialReference
								if theGrid is @rtMoveFromGrid then @sourceSymbol else @targetSymbol
							)
							@miscGraphicsLayer.add thePoint
							theGrid.set "onPointChanged", ({x, y}) =>
								point = new Point thePoint.geometry
								point.x = x
								point.y = y
								thePoint.setGeometry point
							thePoint.pointChanged = =>
								theGrid.setPoint x: thePoint.geometry.x, y: thePoint.geometry.y
							theGrid.graphic = thePoint
				else
					domStyle.set @rtMoveContainer.domNode, "display", "none"
					for theGrid in [@rtMoveFromGrid, @rtMoveToGrid]
						theGrid.setPoint x: "", y: ""
						theGrid.set "onPointChanged", null
						@miscGraphicsLayer.remove theGrid.graphic if theGrid.graphic?
						delete theGrid.graphic
			rt_moveClose: ->
				@rt_moveButton.set "checked", false
			rtMovePick: ({which, state}) ->
				if state
					currentState = "started"
					@map.setMapCursor "crosshair"
					thePoint = null
					theButton = if which is "from" then @rtMoveFromPickButton else @rtMoveToPickButton
					theGrid = if which is "from" then @rtMoveFromGrid else @rtMoveToGrid
					@mouseTip.innerText = "Click to place #{if which is "from" then "Source" else "Target"} Point on the map."
					mouseTipMoveEvent = connect query("body")[0], "onmousemove", (e) =>
						domStyle.set @mouseTip, "display", "block"
						domStyle.set @mouseTip, "left", e.clientX + 20 + "px"
						domStyle.set @mouseTip, "top", e.clientY + 20 + "px"
					mouseTipDownEvent = connect query("body")[0], "onmousedown", (e) =>
						return currentState = "placingPoint.1" if currentState is "placingPoint"
						closeMouseTip?()
						@miscGraphicsLayer.remove thePoint
						theButton.set "checked", false unless theButton.hovering
					mapDownEvent = connect @map, "onMouseDown", (e) =>
						currentState = "placingPoint" if currentState is "started"
					mapUpEvent = connect @map, "onMouseUp", (e) =>
						if currentState is "placingPoint.1"
							currentState = "placedPoint"
							thePoint = new Graphic e.mapPoint, if which is "from" then @sourceSymbol else @targetSymbol
							@miscGraphicsLayer.remove theGrid.graphic if theGrid.graphic?
							@miscGraphicsLayer.add thePoint
							theGrid.setPoint x: e.mapPoint.x, y: e.mapPoint.y
							theGrid.set "onPointChanged", ({x, y}) =>
								point = new Point thePoint.geometry
								point.x = x
								point.y = y
								thePoint.setGeometry point
							thePoint.pointChanged = =>
								theGrid.setPoint x: thePoint.geometry.x, y: thePoint.geometry.y
							theGrid.graphic = thePoint
							closeMouseTip()
							theButton.set "checked", false
					mapDragEvent = connect @map, "onMouseDrag", (e) =>
						currentState = switch currentState
							when "placingPoint.1" then "started"
							else currentState
					closeMouseTip = =>
						disconnect mouseTipMoveEvent
						disconnect mouseTipDownEvent
						disconnect mapDownEvent
						disconnect mapUpEvent
						disconnect mapDragEvent
						domStyle.set @mouseTip, "display", "none"
						@mouseTip.innerText = "..."
						@map.setMapCursor "default"
						currentState = "placedMovePoint"
			rtMoveFromPick: (state) ->
				@rtMovePick which: "from", state: state
			rtMoveToPick: (state) ->
				@rtMovePick which: "to", state: state
			rt_moveTransform: ->
				@projectIfReq
					geometries: [new Point(@rtMoveFromGrid.graphic?.geometry), new Point(@rtMoveToGrid.graphic?.geometry)]
					outSR: @rasters.data.filter((x) => x.rasterId is @currentId)[0].spatialReference
					([fromPoint, toPoint]) =>
						@applyTransform
							tiePoints:
								sourcePoints: for offsets in [[0, 0], [10, 0], [0, 10]]
									point = new Point fromPoint
									point.x += offsets[0]
									point.y += offsets[1]
									point
								targetPoints: for offsets in [[0, 0], [10, 0], [0, 10]]
									point = new Point toPoint
									point.x += offsets[0]
									point.y += offsets[1]
									point
							=> @rt_moveClose()
			rt_scale: (state) ->
				if state
					domStyle.set @rtScaleContainer.domNode, "display", "block"
					for button in [@rt_moveButton, @rt_rotateButton]
						button.set "checked", false
				else
					domStyle.set @rtScaleContainer.domNode, "display", "none"
					@rtScaleFactorInput.value = ""
			rt_scaleClose: ->
				@rt_scaleButton.set "checked", false
			rt_scaleTransform: ->
				request
					url: @imageServiceUrl + "/query"
					content:
						objectIds: @currentId
						returnGeometry: true
						outFields: ""
						f: "json"
					handleAs: "json"
					load: (response) =>
						scaleFactor = unless isNaN @rtScaleFactorInput.value then Number @rtScaleFactorInput.value else 1
						centerPoint = new Polygon(response.features[0].geometry).getExtent().getCenter()
						@applyTransform
							tiePoints:
								sourcePoints: for offsets in [[0, 0], [10, 0], [0, 10]]
									point = new Point centerPoint
									point.x += offsets[0]
									point.y += offsets[1]
									point
								targetPoints: for offsets in [[0, 0], [10 * scaleFactor, 0], [0, 10 * scaleFactor]]
									point = new Point centerPoint
									point.x += offsets[0]
									point.y += offsets[1]
									point
							=> @rt_scaleClose()
					error: ({message}) => console.error message
					(usePost: true)
			rt_rotate: (state) ->
				if state
					domStyle.set @rtRotateContainer.domNode, "display", "block"
					for button in [@rt_moveButton, @rt_scaleButton]
						button.set "checked", false
				else
					domStyle.set @rtRotateContainer.domNode, "display", "none"
					@rtRotateDegreesInput.value = ""
			rt_rotateClose: ->
				@rt_rotateButton.set "checked", false
			rt_rotateTransform: ->
				request
					url: @imageServiceUrl + "/query"
					content:
						objectIds: @currentId
						returnGeometry: true
						outFields: ""
						f: "json"
					handleAs: "json"
					load: (response) =>
						{sin, cos, PI} = Math
						theta = unless isNaN @rtRotateDegreesInput.value then PI / 180 * Number @rtRotateDegreesInput.value else 0
						centerPoint = new Polygon(response.features[0].geometry).getExtent().getCenter()
						@applyTransform
							tiePoints:
								sourcePoints: for offsets in [[0, 0], [10, 0], [0, 10]]
									point = new Point centerPoint
									point.x += offsets[0]
									point.y += offsets[1]
									point
								targetPoints: for offsets in [[0, 0], [10 * cos(theta), 10 * -sin(theta)], [10 * sin(theta), 10 * cos(theta)]]
									point = new Point centerPoint
									point.x += offsets[0]
									point.y += offsets[1]
									point
							=> @rt_rotateClose()
					error: ({message}) => console.error message
					(usePost: true)
			showRasterNotSelectedDialog: ->
				@rasterNotSelectedDialog.show()
			hideRasterNotSelectedDialog: ->
				@rasterNotSelectedDialog.hide()
			selectBasemap: (selectedMenuItem) ->
				menuItems = [
					@selectBasemap_SatelliteButton
					@selectBasemap_HybridButton
					@selectBasemap_TopographicButton
					@selectBasemap_StreetsButton
					@selectBasemap_NaturalVueButton
				]
				for menuItem in menuItems when menuItem isnt selectedMenuItem
					domStyle.set menuItem.domNode, "font-weight", "normal"
				domStyle.set selectedMenuItem.domNode, "font-weight", "bold"
				if @naturalVueServiceLayer?
					@map.removeLayer @naturalVueServiceLayer
					delete @naturalVueServiceLayer
					@map.getLayer(layerId).setVisibility true for layerId in @map.basemapLayerIds
			selectBasemap_Satellite: ->
				@selectBasemap @selectBasemap_SatelliteButton
				@map.setBasemap "satellite"
			selectBasemap_Hybrid: ->
				@selectBasemap @selectBasemap_HybridButton
				@map.setBasemap "hybrid"
			selectBasemap_Topographic: ->
				@selectBasemap @selectBasemap_TopographicButton
				@map.setBasemap "topo"
			selectBasemap_Streets: ->
				@selectBasemap @selectBasemap_StreetsButton
				@map.setBasemap "streets"
			selectBasemap_NaturalVue: ->
				@selectBasemap @selectBasemap_NaturalVueButton
				@map.addLayer (@naturalVueServiceLayer = new ArcGISTiledMapServiceLayer @naturalVueServiceUrl), 1
				@map.getLayer(layerId).setVisibility false for layerId in @map.basemapLayerIds
			atdpContinue: ->
			atdpClose: ->
				popup.close @asyncTaskDetailsPopup
				@asyncResultsGrid.clearSelection()