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
		"esri/layers/ImageServiceParameters"
		"esri/layers/RasterFunction"
		"socket.io/socket.io"
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
		"dijit/Tooltip"
		"eligrey/FileSaver"
	], (declare, _WidgetBase, _TemplatedMixin, _WidgetsInTemplateMixin, template, {connect, disconnect}, ArcGISImageServiceLayer, request, MosaicRule, Polygon, GeometryService, domStyle, PointGrid, Observable, Memory, TiepointsGrid, GraphicsLayer, Color, SimpleMarkerSymbol, SimpleLineSymbol, Graphic, Point, win, domClass, query, editor, RastersGrid, Extent, ProjectParameters, SpatialReference, Url, ArcGISTiledMapServiceLayer, AsyncResultsGrid, popup, CheckBox, aspect, ImageServiceParameters, RasterFunction, io) ->
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
			rastersArchive: null
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
			selectBasemap_dropButton: null
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
			atdpTime: null
			atdpStartTimeTr: null
			atdpEndTimeTr: null
			atdpTimeTr: null
			atdpContinueEvent: null
			atdpContinueButton: null
			confirmActionPopup: null
			confirmActionPopupContinueEvent: null
			collectComputedTiepointsButton: null
			computeAndTransformButton: null
			loadingGif: null
			toggleRasterLayerButton: null
			toggleFootprintsButton: null
			setImageFormat_JPGPNGButton: null
			setImageFormat_JPGButton: null
			rastersDisplayMenu: null
			applyManualTransform_ProjectiveButton: null
			applyManualTransform_1stOrderButton: null
			applyManualTransform_2ndOrderButton: null
			applyManualTransform_3rdOrderButton: null
			applyManualTransform_ProjectiveTooltip: null
			applyManualTransform_1stOrderTooltip: null
			applyManualTransform_2ndOrderTooltip: null
			applyManualTransform_3rdOrderTooltip: null
			footprintsLayer: null
			georefStatus_CompleteButton: null
			georefStatus_FalseButton: null
			georefStatus_PartialButton: null
			georefStatus_WIPButton: null
			georefStatusDropButton: null
			markGeoreferencedButton: null
			openRoughTransformButton: null
			startEditTiepointsButton: null
			socket: null
			wipRasters: null
			sourceSymbol: do ->
				symbol = new SimpleMarkerSymbol(
					SimpleMarkerSymbol.STYLE_X
					10
					new SimpleLineSymbol(
						SimpleLineSymbol.STYLE_SOLID
						new Color [255, 255, 255, 0.5]
						1
					)
					new Color [20, 20, 180]
				)
				symbol.setPath """
					M -7 -5
					L -5 -7
					L  0 -2
					L  5 -7
					L  7 -5
					L  2  0
					L  7  5
					L  5  7
					L  0  2
					L -5  7
					L -7  5
					L -2  0
					L -7 -5
					Z
				"""
				symbol
			targetSymbol: do ->
				symbol = new SimpleMarkerSymbol(
					SimpleMarkerSymbol.STYLE_X
					10
					new SimpleLineSymbol(
						SimpleLineSymbol.STYLE_SOLID
						new Color [255, 255, 255, 0.5]
						1
					)
					new Color [180, 20, 20]
				)
				symbol.setPath """
					M -7 -5
					L -5 -7
					L  0 -2
					L  5 -7
					L  7 -5
					L  2  0
					L  7  5
					L  5  7
					L  0  2
					L -5  7
					L -7  5
					L -2  0
					L -7 -5
					Z
				"""
				symbol
			selectedSourceSymbol: do ->
				symbol = new SimpleMarkerSymbol(
					SimpleMarkerSymbol.STYLE_X
					10
					new SimpleLineSymbol(
						SimpleLineSymbol.STYLE_SOLID
						new Color [255, 255, 255, 0.5]
						1
					)
					new Color [20, 20, 180]
				)
				symbol.setPath """
					M -9.5 -6.5
					L -6.5 -9.5
					L  0   -2
					L  6.5 -9.5
					L  9.5 -6.5
					L  2    0
					L  9.5  6.5
					L  6.5  9.5
					L  0    2
					L -6.5  9.5
					L -9.5  6.5
					L -2    0
					L -9.5 -6.5
					Z
				"""
				symbol
			selectedTargetSymbol: do ->
				symbol = new SimpleMarkerSymbol(
					SimpleMarkerSymbol.STYLE_X
					10
					new SimpleLineSymbol(
						SimpleLineSymbol.STYLE_SOLID
						new Color [255, 255, 255, 0.5]
						1
					)
					new Color [180, 20, 20]
				)
				symbol.setPath """
					M -9.5 -6.5
					L -6.5 -9.5
					L  0   -2
					L  6.5 -9.5
					L  9.5 -6.5
					L  2    0
					L  9.5  6.5
					L  6.5  9.5
					L  0    2
					L -6.5  9.5
					L -9.5  6.5
					L -2    0
					L -9.5 -6.5
					Z
				"""
				symbol
			footprintSymbol:
				new SimpleLineSymbol(
					SimpleLineSymbol.STYLE_SOLID
					new Color [10, 240, 10]
					1
				)
			selectedFootprintSymbol:
				new SimpleLineSymbol(
					SimpleLineSymbol.STYLE_SOLID
					new Color [10, 240, 240]
					2
				)
			scrollToElement: (element) ->
				elemNL = query(element).closest(".dgrid-row")
				if (prevNL = elemNL.prev()).length is 0 or prevNL[0].classList.contains "dgrid-preload"
					elemNL.parent().parent()[0].scrollTop = 0
				else
					win.scrollIntoView prevNL[0]
				win.scrollIntoView element
			postCreate: ->
				imageServiceAuthority = new Url(@imageServiceUrl).authority
				corsEnabledServers = esri.config.defaults.io.corsEnabledServers
				corsEnabledServers.push imageServiceAuthority unless corsEnabledServers.some (x) => x is imageServiceAuthority
				@imageServiceLayer = new ArcGISImageServiceLayer @imageServiceUrl,
					imageServiceParameters: extend(
						new ImageServiceParameters
						renderingRule: extend(
							new RasterFunction
							functionName: "Stretch"
							arguments:
								StretchType: 6
								DRA: true
								MinPercent: 0
								MaxPercent: 2
							variableName: "Raster"
						)
					)
				@imageServiceLayer.setDisableClientCaching true
				@geometryService = new GeometryService @geometryServiceUrl
				onceDone = false
				@watch "map", (attr, oldMap, newMap) =>
					if onceDone then return else onceDone = true
					@map.addLayer @imageServiceLayer
					@footprintsLayer = new GraphicsLayer
					@map.addLayer @footprintsLayer
					@rasters = new Observable new Memory idProperty: "rasterId"
					@rastersGrid = new RastersGrid
						columns: [
							editor
								label: " "
								field: "display"
								editor: CheckBox
								editorArgs: title: "Toggle Visibility"
								sortable: false
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
						sort: "rasterId"
						@rastersGrid
					@rastersGrid.startup()
					domStyle.set @selectRasterContainer.domNode, "display", "block"
					@rastersArchive = []
					@loadRastersList =>
						@refreshMosaicRule()
						domStyle.set @loadingGif, "display", "none"
					@rastersGrid.on ".field-rasterId:click, .field-name:click", (e) =>
						return unless @rastersGrid.cell(e).row?
						@map.setExtent @rastersGrid.cell(e).row.data.footprint.geometry.getExtent() unless @currentGeorefStatus() is 1
						return if @currentGeorefStatus() is 3
						@rastersGrid.clearSelection()
						@rastersGrid.select @rastersGrid.cell(e).row
					@rastersGrid.on "dgrid-select", ({rows}) =>
						oldId = @currentId
						@currentId = rows[0].data.rasterId
						@scrollToElement rows[0].element
						raster.footprint.setSymbol @footprintSymbol for raster in @rasters.data
						rows[0].data.footprint.setSymbol @selectedFootprintSymbol
						if oldId isnt @currentId
							if oldId? and not @rastersArchive[oldId].tiepoints?.data.length > 0 and not @asyncResults.data.some((x) => x.rasterId is oldId and x.status is "Pending")
								@socket.emit "removeWIP", oldId, ({success}) =>
							@socket.emit "addWIP", @currentId, ({success}) =>
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
									@scrollToElement pointGrid.domNode
									rowNL = query(pointGrid.domNode).closest(".dgrid-row")
									rowNL.addClass "yellow"
									mouseUpEvent = connect @tiepointsLayer, "onMouseUp", =>
										rowNL.removeClass "yellow"
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
									@scrollToElement pointGrid.domNode
									rowNL = query(pointGrid.domNode).closest(".dgrid-row")
									rowNL.addClass "yellow"
									mouseUpEvent = connect @tiepointsLayer, "onMouseUp", =>
										rowNL.removeClass "yellow"
										disconnect mouseUpEvent
								pointGrid.domNode
						]
						@tiepointsGrid
					@tiepointsGrid.startup()
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
						@graphicBeingMoved.gotoPointGrid?()
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
						@graphicBeingMoved.pointChanged?()
					connect @map, "onMouseDragEnd", (e) =>
						return unless @graphicBeingMoved?
						@graphicBeingMoved.setGeometry e.mapPoint
						@graphicBeingMoved.pointChanged?()
						delete @graphicBeingMoved
						@map.enablePan()
					connect @map, "onClick", (e) =>
						return unless domStyle.get(@selectRasterContainer.domNode, "display") is "block"
						return if @currentGeorefStatus() is 3
						for raster in @rasters.data by -1 when raster.display
							if raster.footprint.geometry.contains e.mapPoint
								@rastersGrid.clearSelection()
								@rastersGrid.select raster
								break
					connect @map, "onExtentChange", (e) =>
						return if domStyle.get(@selectRasterContainer.domNode, "display") is "none" or @georefStatus_FalseButton.domNode.classList.contains "bold"
						@loadRastersList =>
							@refreshMosaicRule()
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
							atdpTime: "time"
						}
							@[label].innerHTML = row.data[value] ? "--"
						domStyle.set @atdpContinueButton.domNode, "display", if row.data.callback? then "inline-block" else "none"
						domStyle.set @atdpRemoveButton.domNode, "display", if row.data.status is "Pending" then "none" else "block"
						if row.data.time?
							domStyle.set @atdpStartTimeTr, "display", "none"
							domStyle.set @atdpEndTimeTr, "display", "none"
							domStyle.set @atdpTimeTr, "display", "table-row"
						else
							domStyle.set @atdpStartTimeTr, "display", "table-row"
							domStyle.set @atdpEndTimeTr, "display", "table-row"
							domStyle.set @atdpTimeTr, "display", "none"
						@atdpContinueButton.set "label", row.data.callbackLabel ? "Continue Task"
						@atdpContinueEvent = =>
							@atdpClose()
							if row.data.rasterId?
								request
									url: @imageServiceUrl + "/query"
									content:
										f: "json"
										where: "OBJECTID = #{row.data.rasterId}"
										returnGeometry: true
										outFields: "OBJECTID, Name, GeoRefStatus"
									handlesAs: "json"
									load: ({features: [feature]}) =>
										@setGeorefStatus feature.attributes.GeoRefStatus
										@map.setExtent new Polygon(feature.geometry).getExtent()
										mosaicRefreshedAspect = aspect.after @, "refreshMosaicRule", =>
											if mosaicRefreshedAspect.done then return else mosaicRefreshedAspect.done = true
											mosaicRefreshedAspect.remove()
											@rastersGrid.clearSelection()
											@rastersGrid.select @rastersGrid.row row.data.rasterId
											selectAspect = aspect.after @rastersGrid.on "dgrid-select", =>
												if selectAspect.done then return else selectAspect.done = true
												selectAspect.remove()
												row.data.callback?()
									error: ({message}) => console.error message
									(usePost: true)
							else
								row.data.callback?()
						popup.open
							popup: @asyncTaskDetailsPopup
							around: row.element
							orient: ["before-centered", "after-centered", "above-centered"]
						@asyncTaskDetailsPopup.focus()
					connect document, "onkeydown", (e) =>
						return if document.activeElement.tagName.toLowerCase() is "input" and document.activeElement.type.toLowerCase() is "text"
						if e.which == 82
							@toggleRasterLayerButton.set "checked", not @toggleRasterLayerButton.checked
							@toggleRasterLayer @toggleRasterLayerButton.checked
						else if e.which == 70
							@toggleFootprintsButton.set "checked", not @toggleFootprintsButton.checked
							@toggleFootprints @toggleFootprintsButton.checked
					@socket = io.connect()
					@socket.on "connect", =>
						@socket.emit "getWIPs", (wips) =>
							@wipRasters = wips
					@socket.on "addedWIP", (rasterId) =>
						@wipRasters.push rasterId
						@refreshRasterMeta rasterId, =>
							@refreshMosaicRule() if domStyle.get(@selectRasterContainer.domNode, "display") is "block"
					@socket.on "removedWIP", (rasterId) =>
						@wipRasters = @wipRasters.filter (x) => x isnt rasterId
						@refreshRasterMeta rasterId, =>
							@refreshMosaicRule() if domStyle.get(@selectRasterContainer.domNode, "display") is "block"
					@socket.on "modifiedRaster", (rasterId) =>
						@refreshRasterMeta rasterId, =>
							@refreshMosaicRule() if domStyle.get(@selectRasterContainer.domNode, "display") is "block"
					window.self = @
			refreshMosaicRule: (callback) ->
				@imageServiceLayer.setMosaicRule extend(
					new MosaicRule
					method: MosaicRule.METHOD_LOCKRASTER
					lockRasterIds: do =>
						raster.footprint.setSymbol @footprintSymbol for raster in @rasters.data
						@rasters.get(@currentId)?.footprint.setSymbol @selectedFootprintSymbol
						@footprintsLayer.clear()
						if domStyle.get(@selectRasterContainer.domNode, "display") is "block" or not @currentId?
							@imageServiceLayer.setVisibility (raster for raster in @rasters.data when raster.display).length > 0
							@footprintsLayer.add raster.footprint for raster in @rasters.data when raster.display
							raster.rasterId for raster in @rasters.data when raster.display
						else
							@imageServiceLayer.setVisibility true
							@footprintsLayer.add @rasters.get(@currentId).footprint
							[@currentId]
				)
				if not (domStyle.get(@selectRasterContainer.domNode, "display") is "block" or not @currentId?) or (raster for raster in @rasters.data when raster.display).length > 0
					domStyle.set @loadingGif, "display", "block"
					updateEvent = connect @imageServiceLayer, "onUpdateEnd", =>
						disconnect updateEvent
						domStyle.set @loadingGif, "display", "none"
						callback?()
			loadRastersList: (callback) ->
				return callback?() unless @map.extent?
				georefStatus = @currentGeorefStatus()
				request
					url: @imageServiceUrl + "/query"
					content:
						f: "json"
						where: do =>
							wipRs = if @wipRasters.length > 0 then @wipRasters else ["null"]
							if georefStatus isnt 3
								"georefStatus = #{georefStatus}#{if georefStatus is 0 then " OR georefStatus IS NULL" else ""} AND OBJECTID NOT IN (#{wipRs.join ", "})"
							else
								"OBJECTID IN (#{wipRs.join ", "})"
						outFields: "OBJECTID, Name, GeoRefStatus"
						geometry: JSON.stringify @map.extent.toJson() if georefStatus isnt 1 and @map.extent?
						geometryType: "esriGeometryEnvelope"
						spatialRel: "esriSpatialRelIntersects"
					handlesAs: "json"
					load: ({features}) =>
						@footprintsLayer.clear()
						for raster in new Array @rasters.data...
							delete @rastersArchive[raster.rasterId]
							@rastersArchive[raster.rasterId] = raster if not raster.display or raster.tiepoints?
							@rasters.remove raster.rasterId
						for feature in features when feature.attributes.Name isnt "World_Imagery"
							unless (thisRaster = @rastersArchive[feature.attributes.OBJECTID])?
								thisRaster = @rastersArchive[feature.attributes.OBJECTID] =
									rasterId: feature.attributes.OBJECTID
									name: feature.attributes.Name
									spatialReference: new SpatialReference feature.geometry.spatialReference
									display: true
									footprint: new Graphic(
										new Polygon feature.geometry
										if @currentId is feature.attributes.OBJECTID then @selectedFootprintSymbol else @footprintSymbol
									)
							else
								thisRaster.footprint.setGeometry new Polygon feature.geometry
							thisRaster.georefStatus = feature.attributes.GeoRefStatus
							@rasters.put thisRaster
						if domStyle.get(@selectRasterContainer.domNode, "display") is "block"
							@footprintsLayer.add raster.footprint for raster in @rasters.data when raster.display
						else
							@footprintsLayer.add raster.footprint for raster in @rasters.data when raster.footprint.symbol is @selectedFootprintSymbol
						@rastersGrid.set "store", @rasters
						callback?()
						@rastersGrid.clearSelection()
						if @currentId?
							if @rasters.get(@currentId)?
								@rastersGrid.select @currentId
							else
								if @currentId? and not @rastersArchive[@currentId]?.tiepoints?.data.length > 0 and not @asyncResults.data.some((x) => x.rasterId is @currentId and x.status is "Pending")
									@socket.emit "removeWIP", @currentId, ({success}) =>
								delete @currentId
					error: ({message}) => console.error message
					(usePost: true)
			applyTransform: ({tiePoints, gotoLocation, geodataTransform, polynomialOrder}, callback) ->
				gotoLocation ?= true
				geodataTransform ?= "Polynomial"
				polynomialOrder ?= 1
				request
					url: @imageServiceUrl + "/update"
					content:
						f: "json"
						rasterId: @currentId
						geodataTransforms: JSON.stringify [
							geodataTransform: geodataTransform
							geodataTransformArguments:
								sourcePoints: x: point.x, y: point.y for point in tiePoints.sourcePoints
								targetPoints: x: point.x, y: point.y for point in tiePoints.targetPoints
								polynomialOrder: polynomialOrder if geodataTransform is "Polynomial"
								spatialReference: tiePoints.sourcePoints[0].spatialReference
						]
						attributes: JSON.stringify
							GeoRefStatus: 2
					handleAs: "json"
					load: =>
						for task in @asyncResults.data.filter((x) => x.rasterId is @currentId and x.task in ["Compute Tiepoints", "Apply Transform (Tiepoints)"])
							delete task.callback
						selectedRow = @rasters.get @currentId
						@map.setExtent if gotoLocation then selectedRow.footprint.geometry.getExtent() else @map.extent
						@socket.emit "modifiedRaster", @currentId
						callback?()
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
			toggleFootprints: (state) ->
				@footprintsLayer.setOpacity if state then 1 else 0
			startEditTiepoints: ->
				return @showRasterNotSelectedDialog() unless @currentId?
				selectedRow = @rasters.get @currentId
				@tiepointsGrid.set "store", selectedRow.tiepoints ?= new Observable new Memory idProperty: "id"
				for tiepoint in selectedRow.tiepoints.data
					@tiepointsLayer.add tiepoint.sourcePoint
					@tiepointsLayer.add tiepoint.targetPoint
				@applyManualTransform_RefreshButtons()
				for display, containers of {none: [@selectRasterContainer, @tasksContainer, @asyncResultsContainer], block: [@editTiepointsContainer]}
					domStyle.set container.domNode, "display", display for container in containers
				@refreshMosaicRule()
			collectComputedTiepoints: ->
				@confirmActionPopupContinueEvent = =>
					@confirmActionPopupClose()
					@asyncResults.put asyncTask =
						resultId: (Math.max @asyncResults.data.map((x) -> x.resultId).concat(0)...) + 1
						task: "Compute Tiepoints"
						rasterId: @currentId
						status: "Pending"
						startTime: (new Date).toLocaleString()
					domStyle.set @asyncResultsContainer.domNode, "display", "block" if domStyle.get(@selectRasterContainer.domNode, "display") is "block"
					@asyncResultsGrid.select asyncTask
					@closeEditTiepoints()
					@computeTiePoints ({tiePoints, error}) =>
						if error?
							extend asyncTask,
								status: "Failed"
								endTime: (new Date).toLocaleString()
							return @asyncResults.notify asyncTask, asyncTask.resultId
						selectedRow = @rastersArchive[asyncTask.rasterId]
						newId = Math.max(selectedRow.tiepoints.data.map((x) => x.id).concat(0)...) + 1
						for i in [0...tiePoints.sourcePoints.length]
							selectedRow.tiepoints.put
								id: newId + i
								sourcePoint: sourcePoint = new Graphic new Point(tiePoints.sourcePoints[i]), @sourceSymbol
								targetPoint: targetPoint = new Graphic new Point(tiePoints.targetPoints[i]), @targetSymbol
								original:
									sourcePoint: new Point tiePoints.sourcePoints[i]
									targetPoint: new Point tiePoints.targetPoints[i]
							if @rastersGrid.isSelected(selectedRow.rasterId) and domStyle.get(@editTiepointsContainer.domNode, "display") is "block"
								@tiepointsLayer.add sourcePoint
								@tiepointsLayer.add targetPoint
						@applyManualTransform_RefreshButtons() if @rastersGrid.isSelected(selectedRow.rasterId) and domStyle.get(@editTiepointsContainer.domNode, "display") is "block"
						extend asyncTask,
							status: "Completed"
							endTime: (new Date).toLocaleString()
							callback: =>
								@startEditTiepoints()
							callbackLabel: "Edit Tiepoints"
						@asyncResults.notify asyncTask, asyncTask.resultId
				popup.open
					popup: @confirmActionPopup
					around: @collectComputedTiepointsButton.domNode
					orient: ["before-centered", "after-centered", "above-centered"]
				@confirmActionPopup.focus()
			closeEditTiepoints: ->
				@tiepointsLayer.clear()
				for display, containers of {block: [@selectRasterContainer, @tasksContainer], none: [@editTiepointsContainer]}
					domStyle.set container.domNode, "display", display for container in containers
				domStyle.set @asyncResultsContainer.domNode, "display", "block" if @asyncResults.data.length > 0
				@loadRastersList =>
					@refreshMosaicRule()
			toggleTiepointsSelection: ->
				if @toggleTiepointsSelectionMenuItem.label is "Clear Selection"
					@tiepointsGrid.clearSelection()
				else
					@tiepointsGrid.selectAll()
			tiepointsContextMenuOpen: ->
				domStyle.set @resetTiepointMenuItem.domNode, "display", if @tiepointsGrid.cell(@tiepointsContextMenu.currentTarget).row.data.original? then "table-row" else "none"
			removeTiepoint: ->
				selectedRow = @rasters.get @currentId
				selectedRow.tiepoints.remove (tiepoint = @tiepointsGrid.cell(@tiepointsContextMenu.currentTarget).row.data).id
				@tiepointsLayer.remove graphic for graphic in [tiepoint.sourcePoint, tiepoint.targetPoint]
				@applyManualTransform_RefreshButtons()
			resetTiepoint: ->
				tiepoint = @tiepointsGrid.cell(@tiepointsContextMenu.currentTarget).row.data
				for key in ["sourcePoint", "targetPoint"]
					tiepoint[key].setGeometry tiepoint.original[key]
					tiepoint[key].pointChanged()
			addTiepoint: (state) ->
				if state
					selectedRow = @rasters.get @currentId
					currentState = "started"
					@map.setMapCursor "crosshair"
					sourcePoint = null
					targetPoint = null
					@mouseTip.innerHTML = "Click to place Source Point on the map.<br>Right Click to cancel."
					mouseTipMoveEvent = connect query("body")[0], "onmousemove", (e) =>
						domStyle.set @mouseTip, "display", "block"
						domStyle.set @mouseTip, "left", e.clientX + 20 + "px"
						domStyle.set @mouseTip, "top", e.clientY + 20 + "px"
					mouseTipDownEvent = connect query("body")[0], "onmousedown", (e) =>
						return if @toggleRasterLayerButton.hovering
						return currentState = "placingSourcePoint.1" if currentState is "placingSourcePoint"
						return currentState = "placingTargetPoint.1" if currentState is "placingTargetPoint"
						closeMouseTip?() unless e.which is 3
						@tiepointsLayer.remove point for point in [sourcePoint, targetPoint]
						@addTiepointButton.set "checked", false unless @addTiepointButton.hovering
					mapDownEvent = connect @map, "onMouseDown", (e) =>
						return unless e.which is 1
						currentState = switch currentState
							when "started" then "placingSourcePoint"
							when "placedSourcePoint" then "placingTargetPoint"
							else currentState
					mapUpEvent = connect @map, "onMouseUp", (e) =>
						if currentState is "placingSourcePoint.1"
							currentState = "placedSourcePoint"
							sourcePoint = new Graphic e.mapPoint, @sourceSymbol
							@tiepointsLayer.add sourcePoint
							@mouseTip.innerHTML = "Click to place Target Point on the map.<br>Right Click to cancel."
						else if currentState is "placingTargetPoint.1"
							currentState = "placedTargetPoint"
							targetPoint = new Graphic e.mapPoint, @targetSymbol
							@tiepointsLayer.add targetPoint
							selectedRow.tiepoints.put tiepoint =
								id: lastId = Math.max(selectedRow.tiepoints.data.map((x) => x.id).concat(0)...) + 1
								sourcePoint: sourcePoint
								targetPoint: targetPoint
							@applyManualTransform_RefreshButtons()
							closeMouseTip()
							@addTiepoint true
					mapDragEvent = connect @map, "onMouseDrag", (e) =>
						currentState = switch currentState
							when "placingSourcePoint.1" then "started"
							when "placingTargetPoint.1" then "placingTargetPoint"
							else currentState
					contextMenuEvent = connect query("body")[0], "oncontextmenu", (e) =>
						closeMouseTip?()
						e.preventDefault()
					closeMouseTip = =>
						disconnect mouseTipMoveEvent
						disconnect mouseTipDownEvent
						disconnect mapDownEvent
						disconnect mapUpEvent
						disconnect mapDragEvent
						disconnect contextMenuEvent
						domStyle.set @mouseTip, "display", "none"
						@mouseTip.innerHTML = "..."
						@map.setMapCursor "default"
						currentState = "placedTiepoint"
			removeSelectedTiepoints: ->
				selectedRow = @rasters.get @currentId
				for rowId, bool of @tiepointsGrid.selection when bool
					selectedRow.tiepoints.remove (tiepoint = @tiepointsGrid.row(rowId).data).id
					@tiepointsLayer.remove graphic for graphic in [tiepoint.sourcePoint, tiepoint.targetPoint]
				@applyManualTransform_RefreshButtons()
			resetSelectedTiepoints: ->
				for rowId, bool of @tiepointsGrid.selection when bool
					tiepoint = @tiepointsGrid.row(rowId).data
					continue unless tiepoint.original?
					for key in ["sourcePoint", "targetPoint"]
						tiepoint[key].setGeometry tiepoint.original[key]
						tiepoint[key].pointChanged()
			applyManualTransform_RefreshButtons: ->
				selectedRow = @rasters.get @currentId
				@applyManualTransform_ProjectiveButton.set "disabled", selectedRow.tiepoints.data.length < 4
				@applyManualTransform_1stOrderButton.set "disabled", selectedRow.tiepoints.data.length < 3
				@applyManualTransform_2ndOrderButton.set "disabled", selectedRow.tiepoints.data.length < 6
				@applyManualTransform_3rdOrderButton.set "disabled", selectedRow.tiepoints.data.length < 10
				@applyManualTransform_ProjectiveTooltip.set "connectId", (@applyManualTransform_ProjectiveButton.domNode if selectedRow.tiepoints.data.length < 4)
				@applyManualTransform_1stOrderTooltip.set "connectId", (@applyManualTransform_1stOrderButton.domNode if selectedRow.tiepoints.data.length < 3)
				@applyManualTransform_2ndOrderTooltip.set "connectId", (@applyManualTransform_2ndOrderButton.domNode if selectedRow.tiepoints.data.length < 6)
				@applyManualTransform_3rdOrderTooltip.set "connectId", (@applyManualTransform_3rdOrderButton.domNode if selectedRow.tiepoints.data.length < 10)
			applyManualTransform: ({geodataTransform, polynomialOrder} = {}) ->
				domStyle.set @loadingGif, "display", "block"
				selectedRow = @rasters.get @currentId
				@applyTransform
					tiePoints:
						sourcePoints: selectedRow.tiepoints.data.map (x) => x.sourcePoint.geometry
						targetPoints: selectedRow.tiepoints.data.map (x) => x.targetPoint.geometry
					geodataTransform: geodataTransform
					polynomialOrder: polynomialOrder
					=>
						updateEndEvent = connect @imageServiceLayer, "onUpdateEnd", =>
							disconnect updateEndEvent
							appliedTiepoints = new Array selectedRow.tiepoints.data...
							@asyncResults.put asyncTask =
								resultId: (Math.max @asyncResults.data.map((x) -> x.resultId).concat(0)...) + 1
								task: "Apply Transform (Tiepoints)"
								rasterId: @currentId
								status: "Completed"
								time: (new Date).toLocaleString()
								callback: =>
									domStyle.set @loadingGif, "display", "block"
									request
										url: @imageServiceUrl + "/update"
										content:
											f: "json"
											rasterId: @currentId
											geodataTransforms: JSON.stringify [
												geodataTransform: "Identity"
												geodataTransformArguments:
													spatialReference: selectedRow.spatialReference
											]
											geodataTransformApplyMethod: "esriGeodataTransformApplyReplace"
										handleAs: "json"
										load: =>
											for task in @asyncResults.data.filter((x) => x.rasterId is @currentId and x.task in ["Compute Tiepoints", "Apply Transform (Tiepoints)"])
												delete task.callback
											selectedRow = @rasters.get @currentId
											selectedRow.tiepoints.put tiepoint for tiepoint in appliedTiepoints
											delete asyncTask.callback
											@startEditTiepoints()
											domStyle.set @loadingGif, "display", "none"
											@socket.emit "modifiedRaster", @currentId
										error: ({message}) => console.error message
										(usePost: true)
								callbackLabel: "Redo Edit Tiepoints"
							domStyle.set @asyncResultsContainer.domNode, "display", "block" if domStyle.get(@selectRasterContainer.domNode, "display") is "block"
							@asyncResultsGrid.select asyncTask
							selectedRow.tiepoints.remove tiepoint.id for tiepoint in selectedRow.tiepoints.data.splice 0
							@closeEditTiepoints()
							domStyle.set @loadingGif, "display", "none"
			applyManualTransform_Projective: ->
				@applyManualTransform geodataTransform: "Projective"
			applyManualTransform_1stOrder: ->
				@applyManualTransform geodataTransform: "Polynomial", polynomialOrder: 1
			applyManualTransform_2ndOrder: ->
				@applyManualTransform geodataTransform: "Polynomial", polynomialOrder: 2
			applyManualTransform_3rdOrder: ->
				@applyManualTransform geodataTransform: "Polynomial", polynomialOrder: 3
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
				@loadRastersList =>
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
			applyRoughTransform: (argObj, callback) ->
				@applyTransform argObj, =>
					@refreshRasterMeta @currentId, =>
						callback?()
			rt_fit: ->
				domStyle.set @loadingGif, "display", "block"
				@projectIfReq
					geometries: (@rastersGrid.row(rowId).data.footprint.geometry.getExtent() for rowId, bool of @rastersGrid.selection when bool).concat @map.extent
					outSR: @rasters.data.filter((x) => x.rasterId is @currentId)[0].spatialReference
					([fromExt, mapExtent]) =>
						@applyRoughTransform
							tiePoints:
								sourcePoints: [
									new Point x: fromExt.xmin, y: fromExt.ymin, spatialReference: fromExt.spatialReference
									new Point x: fromExt.xmin, y: fromExt.ymax, spatialReference: fromExt.spatialReference
									new Point x: fromExt.xmax, y: fromExt.ymin, spatialReference: fromExt.spatialReference
								]
								targetPoints: do =>
									aspectRatio = (fromExt.xmax - fromExt.xmin) / (fromExt.ymax - fromExt.ymin)
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
							gotoLocation: false
							=>
								updateEndEvent = connect @imageServiceLayer, "onUpdateEnd", =>
									disconnect updateEndEvent
									domStyle.set @loadingGif, "display", "none"
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
					@rtMoveFromPick true
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
					@mouseTip.innerHTML = "Click to place #{if which is "from" then "Source" else "Target"} Point on the map.<br>Right Click to cancel."
					mouseTipMoveEvent = connect query("body")[0], "onmousemove", (e) =>
						domStyle.set @mouseTip, "display", "block"
						domStyle.set @mouseTip, "left", e.clientX + 20 + "px"
						domStyle.set @mouseTip, "top", e.clientY + 20 + "px"
					mouseTipDownEvent = connect query("body")[0], "onmousedown", (e) =>
						return if @toggleRasterLayerButton.hovering
						return currentState = "placingPoint.1" if currentState is "placingPoint"
						closeMouseTip?() unless e.which is 3
						@miscGraphicsLayer.remove thePoint
						theButton.set "checked", false unless theButton.hovering
					mapDownEvent = connect @map, "onMouseDown", (e) =>
						return unless e.which is 1
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
							@rtMoveToPickButton.set "checked", true if theButton is @rtMoveFromPickButton
					mapDragEvent = connect @map, "onMouseDrag", (e) =>
						currentState = switch currentState
							when "placingPoint.1" then "started"
							else currentState
					contextMenuEvent = connect query("body")[0], "oncontextmenu", (e) =>
						closeMouseTip?()
						e.preventDefault()
					closeMouseTip = =>
						disconnect mouseTipMoveEvent
						disconnect mouseTipDownEvent
						disconnect mapDownEvent
						disconnect mapUpEvent
						disconnect mapDragEvent
						disconnect contextMenuEvent
						domStyle.set @mouseTip, "display", "none"
						@mouseTip.innerHTML = "..."
						@map.setMapCursor "default"
						currentState = "placedMovePoint"
			rtMoveFromPick: (state) ->
				@rtMovePick which: "from", state: state
			rtMoveToPick: (state) ->
				@rtMovePick which: "to", state: state
			rt_moveTransform: ->
				domStyle.set @loadingGif, "display", "block"
				@projectIfReq
					geometries: [new Point(@rtMoveFromGrid.graphic?.geometry), new Point(@rtMoveToGrid.graphic?.geometry)]
					outSR: @rasters.data.filter((x) => x.rasterId is @currentId)[0].spatialReference
					([fromPoint, toPoint]) =>
						@applyRoughTransform
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
							gotoLocation: false
							=>
								updateEndEvent = connect @imageServiceLayer, "onUpdateEnd", =>
									disconnect updateEndEvent
									@rt_moveClose()
									domStyle.set @loadingGif, "display", "none"
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
				domStyle.set @loadingGif, "display", "block"
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
						@applyRoughTransform
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
							gotoLocation: false
							=>
								updateEndEvent = connect @imageServiceLayer, "onUpdateEnd", =>
									disconnect updateEndEvent
									@rt_scaleClose()
									domStyle.set @loadingGif, "display", "none"
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
				domStyle.set @loadingGif, "display", "block"
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
						@applyRoughTransform
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
							gotoLocation: false
							=>
								updateEndEvent = connect @imageServiceLayer, "onUpdateEnd", =>
									disconnect updateEndEvent
									@rt_rotateClose()
									domStyle.set @loadingGif, "display", "none"
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
					query(menuItem.domNode).removeClass "bold"
				query(selectedMenuItem.domNode).addClass "bold"
				@selectBasemap_dropButton.set "label", selectedMenuItem.label
				if @naturalVueServiceLayer?
					@map.removeLayer @naturalVueServiceLayer
					@naturalVueServiceLayer.suspend()
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
			atdpClose: ->
				popup.close @asyncTaskDetailsPopup
				@asyncResultsGrid.clearSelection()
			atdpContinue: ->
				@atdpContinueEvent?()
			atdpRemove: ->
				for rowId, bool of @asyncResultsGrid.selection when bool
					@asyncResults.remove rowId
				@atdpClose()
				domStyle.set @asyncResultsContainer.domNode, "display", "none" if @asyncResults.data.length is 0
			confirmActionPopupClose: ->
				popup.close @confirmActionPopup
			confirmActionPopupContinue: ->
				@confirmActionPopupContinueEvent?()
			setImageFormat: (selectedMenuItem) ->
				menuItems = [
					@setImageFormat_JPGPNGButton
					@setImageFormat_JPGButton
				]
				for menuItem in menuItems when menuItem isnt selectedMenuItem
					menuItem.set "checked", false
				selectedMenuItem.set "checked", true
			setImageFormat_JPGPNG: ->
				@setImageFormat @setImageFormat_JPGPNGButton
				@imageServiceLayer.setImageFormat "jpgpng"
			setImageFormat_JPG: ->
				@setImageFormat @setImageFormat_JPGButton
				@imageServiceLayer.setImageFormat "jpg"
			rastersDisplay_enableAll: ->
				for raster in @rasters.data
					raster.display = true
					@rasters.notify raster, raster.rasterId
				@rastersGrid.select @currentId if @currentId?
				@refreshMosaicRule()
			rastersDisplay_disableAll: ->
				for raster in @rasters.data
					raster.display = false
					@rasters.notify raster, raster.rasterId
				@rastersGrid.select @currentId if @currentId?
				@refreshMosaicRule()
			importTiepoints: ->
				ipElement = document.createElement "input"
				ipElement.type = "file"
				ipElement.accept = "text/plain"
				ipElement.click()
				reader = new FileReader
				changeEvent = connect ipElement, "onchange", (event) ->
					console.log @files
					disconnect changeEvent
					reader.readAsText @files[0]
				reader.onload = ({target: {result}}) =>
					selectedRow = @rasters.get @currentId
					newId = Math.max(selectedRow.tiepoints.data.map((x) => x.id).concat(0)...) + 1
					tiepoints = result.match(/^.+$/gm).map (x) =>
						arr = x.split(/\t/g).map (x) => Number x
						sourcePoint: x: arr[0], y: arr[1], spatialReference: @map.spatialReference
						targetPoint: x: arr[2], y: arr[3], spatialReference: @map.spatialReference
					for i in [0...tiepoints.length]
						selectedRow.tiepoints.put
							id: newId + i
							sourcePoint: sourcePoint = new Graphic new Point(tiepoints[i].sourcePoint), @sourceSymbol
							targetPoint: targetPoint = new Graphic new Point(tiepoints[i].targetPoint), @targetSymbol
							original:
								sourcePoint: new Point tiepoints[i].sourcePoint
								targetPoint: new Point tiepoints[i].targetPoint
							@tiepointsLayer.add sourcePoint
							@tiepointsLayer.add targetPoint
					@applyManualTransform_RefreshButtons() if @rastersGrid.isSelected(selectedRow.rasterId) and domStyle.get(@editTiepointsContainer.domNode, "display") is "block"
			exportTiepoints: ->
				selectedRow = @rasters.get @currentId
				blob = new Blob ["Hello, world!"], type: "text/plain;charset=utf-8"
				saveAs(
					new Blob [
						selectedRow.tiepoints.data.map((x) => [
							x.sourcePoint.geometry.x
							x.sourcePoint.geometry.y
							x.targetPoint.geometry.x
							x.targetPoint.geometry.y
						].join "\t").join "\r\n"
					]
					"tiepoints_raster#{selectedRow.rasterId}.txt"
				)
			refreshRasterMeta: (rasterId, callback) ->
				request
					url: @imageServiceUrl + "/query"
					content:
						f: "json"
						where: "OBJECTID = #{rasterId}"
						outFields: "OBJECTID, Name, GeoRefStatus"
					handlesAs: "json"
					load: ({features: [feature]}) =>
						georefStatus = @currentGeorefStatus()
						footprintGeometry = new Polygon feature.geometry
						feature.attributes.GeoRefStatus = 3 if rasterId in @wipRasters
						return callback?() unless @rastersArchive[rasterId]? or (georefStatus is feature.attributes.GeoRefStatus and (georefStatus is 1 or @map.extent.intersects footprintGeometry))
						if @rastersArchive[rasterId]?
							@rastersArchive[rasterId].footprint.setGeometry footprintGeometry
						else
							@rastersArchive[rasterId] =
								rasterId: feature.attributes.OBJECTID
								name: feature.attributes.Name
								spatialReference: new SpatialReference feature.geometry.spatialReference
								display: true
								footprint: new Graphic(
									footprintGeometry
									if @currentId is feature.attributes.OBJECTID then @selectedFootprintSymbol else @footprintSymbol
								)
						@rastersArchive[rasterId].georefStatus = feature.attributes.GeoRefStatus
						if georefStatus is feature.attributes.GeoRefStatus and (georefStatus is 1 or @map.extent.intersects footprintGeometry)
							@rasters.put @rastersArchive[rasterId]
						else
							@rasters.remove rasterId
						callback?()
					error: ({message}) => console.error message
					(usePost: true)
			currentGeorefStatus: ->
				if @georefStatus_CompleteButton.domNode.classList.contains "bold"
					0
				else if @georefStatus_FalseButton.domNode.classList.contains "bold"
					1
				else if @georefStatus_PartialButton.domNode.classList.contains "bold"
					2
				else if @georefStatus_WIPButton.domNode.classList.contains "bold"
					3
			setGeorefStatus: (num) ->
				switch num
					when 0 then @georefStatus_Complete()
					when 1 then @georefStatus_False()
					when 2 then @georefStatus_Partial()
					when 3 then @georefStatus_WIP()
			georefStatus: (selectedMenuItem) ->
				menuItems = [
					@georefStatus_CompleteButton
					@georefStatus_FalseButton
					@georefStatus_PartialButton
					@georefStatus_WIPButton
				]
				for menuItem in menuItems when menuItem isnt selectedMenuItem
					query(menuItem.domNode).removeClass "bold"
				query(selectedMenuItem.domNode).addClass "bold"
				@georefStatusDropButton.set "label", selectedMenuItem.label
				@markGeoreferencedButton.set "disabled", selectedMenuItem in [
					@georefStatus_CompleteButton
					@georefStatus_WIPButton
				]
				button.set "disabled", selectedMenuItem is @georefStatus_WIPButton for button in [
					@openRoughTransformButton
					@startEditTiepointsButton
				]
				@loadRastersList =>
					@refreshMosaicRule()
			georefStatus_Complete: ->
				@georefStatus @georefStatus_CompleteButton
			georefStatus_False: ->
				@georefStatus @georefStatus_FalseButton
			georefStatus_Partial: ->
				@georefStatus @georefStatus_PartialButton
			georefStatus_WIP: ->
				@georefStatus @georefStatus_WIPButton
			markGeoreferenced: ->
				return @showRasterNotSelectedDialog() unless @currentId?
				request
					url: @imageServiceUrl + "/update"
					content:
						f: "json"
						rasterId: @currentId
						attributes: JSON.stringify
							GeoRefStatus: 0
					handleAs: "json"
					load: =>
						@loadRastersList =>
							@refreshMosaicRule()
						@socket.emit "modifiedRaster", @currentId
					error: ({message}) => console.error message
					(usePost: true)