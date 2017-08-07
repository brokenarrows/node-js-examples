if typeof BASE_URL == 'undefined'
  BASE_URL = '/'
if typeof BASE_URL_CDN == 'undefined'
  BASE_URL_CDN = 'https://cdn-stepstowar.site/'
if typeof IS_GAME == 'undefined'
  IS_GAME = true
mapModule = mapModule or {}
((local) ->
  _token = $('[name="csrf_token"]').attr('content')
  mapType = 'world'
  gameType = undefined
  isInteractive = undefined
  mapCoordinates = undefined
  map = ''
  mapMaxZoom = 8
  mapFeatureElement = undefined
  mapIsWarNation = false
  mapSearch = undefined
  ajaxRequestMap = undefined
  layerMiniMap = undefined
  layerGeoJson = ''
  layerOSM = undefined
  layerControl = L.control()
  layerShown = undefined
  layerPolygon = undefined
  layerTerminator = undefined
  layerSideBar = undefined
  layerFeatureHighlight = undefined
  layerTile = undefined
  baseLayers = undefined
  earth = undefined
  layerFillColor = undefined
  layerFillOpacity = 0.3
  layerFillWeight = 2
  layerFillTextColor = '#fff'
  layerFillDashArray = 3
  LayerFillTextOpacity = 1
  markers = new (L.FeatureGroup)
  markerCapital = undefined
  markerCapitalOwner = undefined
  markerNation = undefined
  markerNationOwner = undefined
  markerEnemy = undefined
  markerClusterGroup = undefined
  markerClusterLat = 0
  markerClusterLng = 0
  filter = false
  filterKey = null
  filterId = 0
  timerInfo = undefined
  isWizard = undefined
  timeoutHandler = undefined
  sbs = undefined
  sbs_exists = false
  sbs_layer = undefined
  layer_comparison_1 = undefined
  layer_comparison_2 = undefined
  mapId = undefined
  nationId = undefined
  globe = false
  location_info_timeout = undefined
  Green2Red = [
    {
      pct: 0.0
      color:
        r: 0x00
        g: 0xff
        b: 0
    }
    {
      pct: 0.5
      color:
        r: 0xff
        g: 0xff
        b: 0
    }
    {
      pct: 1.0
      color:
        r: 0xff
        g: 0x00
        b: 0
    }
  ]
  Red2Green = [
    {
      pct: 0.0
      color:
        r: 0xff
        g: 0x00
        b: 0
    }
    {
      pct: 0.5
      color:
        r: 0xff
        g: 0xff
        b: 0
    }
    {
      pct: 1.0
      color:
        r: 0x00
        g: 0xff
        b: 0
    }
  ]
  options =
    radius: 100
    opacity: 0.9
    duration: 200
    lng: (d) ->
      d[0]
    lat: (d) ->
      d[1]
    value: (d) ->
      d.length
    valueFloor: 0
    valueCeil: undefined
    colorRange: [
      '#f7fbff'
      '#08306b'
    ]
    onmouseover: (d, node, layer) ->
    onmouseout: (d, node, layer) ->
    onclick: (d, node, layer) ->
  local.getHost = ->
#url = BASE_URL + 'cdn/worldmap/{z}-r{y}-c{x}.jpg';
    url = BASE_URL + 'cdn/worldmap/{z}-r{y}-c{x}.jpg'
    if local.getMapType() == 'world'
      url = 'https://{s}.stepstowar.com/cdn/worldmap/{z}-r{y}-c{x}.jpg'
    else if local.getMapType() == 'war'
      url = 'https://{s}.stepstowar.com/cdn/warmap/{z}-r{y}-c{x}.jpg'
    else if local.getMapType() == 'strategy'
      url = 'https://{s}.stepstowar.com/cdn/worldmap/{z}-r{y}-c{x}.jpg'
    # var url = 'http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}.jpg';
    url

  local.initalize = (lat, lng, zoom, zoomsliderControl) ->
    map = L.map('map',
      maxZoom: local.getMaxZoom()
      zoomControl: false
      zoomsliderControl: zoomsliderControl
      attributionControl: false
      contextmenu: false).setView([
      lat
      lng
    ], zoom)
    southWest = L.latLng(-90, -190)
    northEast = L.latLng(90, 190)
    bounds = L.latLngBounds(southWest, northEast)
    map.setMaxBounds bounds
    layerTile = L.tileLayer(local.getHost(),
      maxZoom: local.getMaxZoom()
      noWrap: false).addTo(map)
    local.invalidateMap()
    if local.getGameType() == 2 or local.getGameType() == 3
      local.initializeLayersWeather()
    if local.getGameType() == 3
      svg = d3.select(map.getPanes().overlayPane).append('svg')
      g = svg.append('g').attr('class', 'leaflet-zoom-hide')
      # reset();
      #Import the plane
      element = document.getElementById('diagram-pathfinding')
      element.style = ''
      map.getPanes().overlayPane.appendChild element
      # map.panTo(new L.LatLng(21.115, 22.742, 13));
      map.zoomIn 13
    return

  local.initializeGlobe = ->
    map = new (WE.map)('map')
    map.setView [
      46.8011
      8.2266
    ], 2
    WE.tileLayer('http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}.jpg',
      tileSize: 256
      bounds: [
        [
          -85
          -180
        ]
        [
          85
          180
        ]
      ]
      minZoom: 0
      maxZoom: 13
      attribution: 'Earth'
      tms: false).addTo map
    return

  local.initializeLayerOnly = ->
    map.eachLayer (layer) ->
      map.removeLayer layer
      return
    map.removeLayer earth
    layerTile = L.tileLayer(local.getHost(),
      maxZoom: local.getMaxZoom()
      noWrap: false).addTo(map)
    local.invalidateMap()
    return

  local.initializeLayersWeather = ->
    earth = L.layerGroup()
    pressure = L.tileLayer('https://a.maps.owm.io/map/pressure_new/{z}/{x}/{y}?{appid}',
      noWrap: false
      appid: 'appid=b1b15e88fa797225412429c1c50c122a1').addTo(earth)
    precipitation = L.tileLayer('https://a.maps.owm.io/map/precipitation_new/{z}/{x}/{y}?{appid}',
      noWrap: false
      appid: 'appid=b1b15e88fa797225412429c1c50c122a1').addTo(earth)
    wind = L.tileLayer('https://a.maps.owm.io/map/wind_new/{z}/{x}/{y}?{appid}',
      noWrap: false
      appid: 'appid=b1b15e88fa797225412429c1c50c122a1').addTo(earth)
    clouds = L.tileLayer('https://a.maps.owm.io/map/clouds_new/{z}/{x}/{y}?{appid}',
      noWrap: false
      appid: 'appid=b1b15e88fa797225412429c1c50c122a1').addTo(earth)
    temp = L.tileLayer('https://a.maps.owm.io/map/temp_new/{z}/{x}/{y}?{appid}',
      noWrap: false
      appid: 'appid=b1b15e88fa797225412429c1c50c122a1').addTo(earth)
    world = L.tileLayer(local.getHost(), noWrap: false).addTo(earth)
    baseLayers =
      'World': world
      'Pressure': pressure
      'Precipitation': precipitation
      'Wind': wind
      'Clouds': clouds
      'Temperature': temp
    L.control.layers(baseLayers).addTo map

    local.dayAndNight()
    local.invalidateMap()
    return

  local.dayAndNight = ->
    L.terminator time: '2017-06-19T12:01:00Z'
    timeString = '2017-06-20T12:00:00'
    startTime = new Date(timeString)
    t = L.terminator()
    t.addTo map

    ###
     Every day is 240 seconds ( minutes)
     Every 1 hour = 10 seconds
     every 10 minutes = 1.6666 seconds
     every 1 minute = 0.1666 seconds
    ###

    local.updateTerminator t, startTime
    setInterval (->
      local.updateTerminator t, startTime
      return
    ), 10000
    return

  local.updateTerminator = (t, startTime) ->
    startTime.setHours startTime.getHours() + 1
    if startTime.getHours() == 0
      startTime.setHours startTime.getDay() + 1
    t2 = L.terminator(time: startTime)
    t.setLatLngs t2.getLatLngs()
    t.redraw()
    return

  local.mapMoveHandler = (panToLocation) ->
# cancel any timeout currently running
    window.clearTimeout timeoutHandler
    # create new timeout to fire sesarch function after 500ms (or whatever you like)
    timeoutHandler = window.setTimeout((->
      local.onMapMovement panToLocation
      return
    ), 0)
    return

  local.mapDragHandler = ->
# cancel any timeout currently running
    window.clearTimeout timeoutHandler
    return

  local.invalidateMap = ->
    if local.getGameType() == 1
      doc_height = parseInt($('.panel.form-wizard').height()) + 100
      if $(window).height() > doc_height
        doc_height = $(window).height()
      $('#map').css
        width: $(window).width()
        height: doc_height
        top: 0
    else if local.getGameType() == 2
      $('#map').css
        width: parseInt($(window).width()) + 'px'
        height: parseInt($(window).height() - $('.page-header').height()) + 'px'
        left: 0
        top: 55 + 'px'
        position: 'absolute'
    else if local.getGameType() == 3
      $('#map').css
        width: $(window).width() + 'px'
        height: parseInt($(window).height() - $('.page-header').height()) + 'px'
        left: 0
        top: 55 + 'px'
    map.invalidateSize()
    return

  local.onMapMovement = (panToLocation) ->
    map.removeLayer layerGeoJson
    local.generateBoundary panToLocation
    return

  local.enableInteraction = (value) ->
    if IS_MOBILE
      return false
    if value
      map.dragging.enable()
      map.touchZoom.enable()
      map.doubleClickZoom.enable()
      map.scrollWheelZoom.enable()
      map.boxZoom.enable()
      map.keyboard.enable()
      new (L.Hash)(map)
      map.on 'move', ->
        local.mapMoveHandler true
        local.hideContextMenu()
        return
      map.on 'zoomend', ->
        local.mapMoveHandler true
        local.hideContextMenu()
        return
      map.on 'moveend', ->
        local.mapMoveHandler true
        local.hideContextMenu()
        return
      map.on 'dragend', ->
        local.mapMoveHandler true
        local.hideContextMenu()
        return
      map.on 'drag', ->
        local.mapDragHandler()
        local.hideContextMenu()
        return
      map.on 'zoom', ->
        local.mapDragHandler()
        local.hideContextMenu()
        return
      $('.leaflet-control-zoomslider').show()
      $('.leaflet-container').css 'cursor', 'drag'
    else
      map.dragging.disable()
      map.touchZoom.disable()
      map.doubleClickZoom.disable()
      map.scrollWheelZoom.disable()
      map.boxZoom.disable()
      map.keyboard.disable()
      $('.leaflet-control-zoomslider').hide()
      $('.leaflet-container').css 'cursor', 'default'
    return

  local.enableWarInteraction = (value) ->
    if value
      map.dragging.disable()
      map.touchZoom.disable()
      map.doubleClickZoom.disable()
      map.scrollWheelZoom.disable()
      map.boxZoom.disable()
      map.keyboard.disable()
      $('.leaflet-control-zoomslider').hide()
    return

  local.isWater = (type) ->
    lat = undefined
    lng = undefined
    if type == 'polyline'
      lat = e.lat
      lng = e.lng
    else
      lat = e._latlng.lat
      lng = e._latlng.lng
    image = new Image
    context = $('canvas.map')[0].getContext('2d')
    image.src = BASE_URL + 'warmode/fetch/map/' + lat + '/' + lng

    image.onload = ->
      context.drawImage image, 0, 0, 256, 256
      pixels = context.getImageData(1, 1, 1, 1).data
      if local.isColorWater(pixels)
        swal 'You can\'t play land units on water', '', 'error'
      return

    return

  local.isColorWater = (bytes) ->
    water_color_bytes = [
      0
      254
      0
    ]
    our_color_bytes = [
      bytes[0]
      bytes[1]
      bytes[2]
    ]
    _.isEqual water_color_bytes, our_color_bytes

  local.modeWarButton = ->
    L.easyButton 'fa-fighter-jet', (->
      local.isWarMode true
      return
    ), 'War Mode', 'btn_warmode', map
    return

  local.goHome = ->
    $.ajax(
      type: 'post'
      url: BASE_URL + 'ajax/map/capital'
      data: '&_token=' + $('[name="csrf_token"]').attr('content')
      dataType: 'json').done (data) ->
    map.panTo new (L.LatLng)(data.lat, data.lon, 8)
    map.zoomIn 8
    return
    return

  local.modeHomeButton = ->
    L.easyButton 'fa-home', (->
      local.goHome()
      return
    ), 'Go to Capital', 'btn_gotocapital', map
    return

  local.modeNormalButton = ->
    L.easyButton 'fa-trophy', (->
      local.isWarMode false
      return
    ), 'Normal Mode', 'btn_normalmode', map
    return

  local.modeCompareButton = ->
    L.easyButton ' fa-map-signs', (->
      local.enableComparison()
      return
    ), 'Compare Mode', 'btn_comparemode', map
    return

  local.modeGlobeButton = ->
    L.easyButton ' fa-globe', (->
      local.enableGlobe()
      return
    ), 'Globe Mode', 'btn_globemode', map
    return

  local.enableGlobe = ->
    map.remove()
    if globe == false
      local.initializeGlobe()
    else
      local.initializeLayerOnly()
    return

  local.enableMapFilter = (filter) ->
    local.setFilter filter
    local.generateBoundary()
    return

  local.pluginTerminator = (status) ->
    if status
      layerTerminator = L.terminator().addTo(map)
    else
      layerTerminator.removeFrom map
    return

  local.pluginSideBar = (status) ->
    if status
      layerSideBar = L.control.sidebar('sidebar').addTo(map)
    else
      layerSideBar.removeFrom map
    return

  local.pluginMiniMap = (status) ->
    if status
      layerOSM = new (L.TileLayer)(local.getHost(),
        noWrap: false
        minZoom: 1
        maxZoom: mapMaxZoom
        toggleDisplay: false)
      layerMiniMap = new (L.Control.MiniMap)(layerOSM).addTo(map)
    else
      layerMiniMap.removeFrom map
    return

  local.pluginMapFilter = (key, id) ->
    $('#context-menu-layer:gt(2)').remove()
    $('.context-menu-root:gt(2)').remove()
    if key != 'thermal'
      local.setFilter id
      local.setFilterId key
      local.legendInfoLayer key, id
    else
      local.setFilterId 0
      local.setFilter 'nations'
      $('.selected_item').remove()
      $('.info_legend').remove()
    local.generateBoundary()
    return

  local.pluginCoordinates = ->
    mapCoordinates = L.control.coordinates(
      position: 'bottomright'
      decimals: 2
      decimalSeperator: '.'
      labelTemplateLat: 'Latitude: {y}'
      labelTemplateLng: 'Longitude: {x}'
      enableUserInput: true
      useDMS: false
      useLatLngOrder: true).addTo(map)
    return

  local.legendInfoLayer = (key, type) ->
    color = 'r2g'
    $('.info_legend').remove()
    console.log type
    if type == 'gdp'
      color = 'r2g'
    if type == 'gdp_growth'
      color = 'r2g'
    if type == 'birth_rate'
      color = 'r2g'
    if type == 'death_rate'
      color = 'g2r'
    if type == 'corruption'
      color = 'g2r'
    if type == 'debt'
      color = 'g2r'
    if type == 'inflation'
      color = 'g2r'
    if type == 'credit_rating'
      color = 'g2r'
    if type == 'population'
      color = 'r2g'
    if type == 'economy'
      color = 'r2g'
    if type == 'military'
      color = 'r2g'
    if type == 'research'
      color = 'r2g'
    if type == 'resources'
      color = 'r2g'
    if type == 'human_development'
      color = 'r2g'
    if type == 'relations'
      color = 'r2g'
    if type == 'political'
      color = 'r2g'
    if type == 'wars'
      color = 'r2g'
    if type == 'political'
      return false
    width = parseInt($(window).width() - $('#sidebar-left').width())
    thisKey = $('.' + key + ' span').first()
    thisKeyText = thisKey.text()
    legend = L.control(position: 'bottomleft')
    if type == 'relations'

      legend.onAdd = (map) ->
        div = L.DomUtil.create('div', 'info_legend')
        div.style.width = '225px'
        html = '<span style="width:100%" class="title">Legend: ' + thisKeyText + '</span> <div class="clearfix"></div> '
        html += '<div class="">'
        html += '<table class="table table-bordered" style="background: #171717; opacity:0.75">'
        html += '<tbody>'
        html += '<tr> <td>Cold</td> <td style="background-color: #00ffd7"></td> </tr>'
        html += '<tr> <td>Neutral</td>  <td style="background-color: #dae3e3"></td> </tr>'
        html += '<tr> <td>Warm</td>  <td style="background-color: #ffe513"></td> </tr>'
        html += '<tr> <td>Hot</td>  <td style="background-color: #ff9805"></td> </tr>'
        html += '</tbody>'
        html += '</table>'
        html += '</div>'
        div.innerHTML = html
        div

    else

      legend.onAdd = (map) ->
        div = L.DomUtil.create('div', 'info_legend')
        div.style.width = width + 'px'
        html = '<span class="title">Legend: ' + thisKeyText + '</span> <div class="clearfix"></div> '
        html += '<ul style="padding-left:0"> '
        ul = document.createElement('ul')
        i = 0
        l = 25
        while i <= l
          html += '<li style="width: ' + parseInt(width / 26.5) + 'px;background-color:' + local.getColorForPercentage(i / l, color) + '"> ' + (i / l * 100).toFixed(0) + '%' + ' </li>'
          i++
        html += '</ul> '
        div.innerHTML = html
        div

    legend.addTo map

  local.legendWars = (key) ->

  local.generateBoundary = (panToLocation) ->
    if local.getFilterId() > 0
      mapIsWarNation = true
    center = map.getCenter()
    zoom = map.getZoom()
    bounds = map.getBounds()
    min = bounds.getSouthWest().wrap()
    max = bounds.getNorthEast().wrap()
    if zoom > 4
      if panToLocation
        map.panTo new (L.LatLng)(center.lat, center.lng, zoom)
      local.getJsonByBoundary min.lng, min.lat, max.lng, max.lat, mapIsWarNation
    else
      map.removeLayer markers
    map.invalidateSize()
    return

  local.getJsonByBoundary = (lon1, lat1, lon2, lat2, warnation) ->
    map.removeLayer layerGeoJson
    # map.removeLayer(hexLayer);
    data =
      'lat1': lat1
      'lat2': lat2
      'lon1': lon1
      'lon2': lon2
      'type': local.getGameType()
      'wizard': local.getGameType()
      'filter': local.getFilter()
      'filter_id': local.getFilterId()
      '_token': $('[name="csrf_token"]').attr('content')
    if ajaxRequestMap
      ajaxRequestMap.abort()
    ajaxRequestMap = $.ajax(
      type: 'post'
      url: BASE_URL + 'ajax/map/boundary'
      data: data
      dataType: 'json').done((data) ->
      map.removeLayer layerGeoJson
      if warnation
        layerGeoJson = L.geoJson(data,
          style: local.layerFeatureStyle
          onEachFeature: local.layerOnEachFeature).addTo(map)
        map.touchZoom.disable()
        map.doubleClickZoom.disable()
        map.scrollWheelZoom.disable()
        map.boxZoom.disable()
        map.keyboard.disable()
      else
        layerGeoJson = L.geoJson(data,
          style: local.layerFeatureStyle
          onEachFeature: local.layerOnEachFeature).addTo(map)
      return
    )
    return

  local.getCurrentLocation = ->
    center = map.getCenter()
    zoom = map.getZoom()
    bounds = map.getBounds()
    min = bounds.getSouthWest().wrap()
    max = bounds.getNorthEast().wrap()
    [
      min
      max
      center
      zoom
    ]

  local.getNationSearchInfo = (url) ->
    mapSearch = map.addControl(new (L.Control.Search)(
      url: url
      text: 'Search Nation'
      markerLocation: true))
    return

  local.getNationInfo = (id, type) ->
    url_type = undefined
    if type == 'basic'
      url_type = BASE_URL + 'ajax/map/nation'
    else
      url_type = BASE_URL + 'ajax/map/nation_detail'
    $.ajax(
      type: 'post'
      url: url_type
      data:
        'id': id
        '_token': _token
        'type': type
      dataType: 'json').done (data) ->
    if type == 'basic'
      local.setInfoPanel data
    else if type == 'detail'
      local.setModalPanel data, '.modal-basic'
    return
    return

  local.getLocationInfo = (id, type) ->
    url_type = undefined
    if type == 'basic'
      url_type = BASE_URL + 'ajax/map/location'
    else
      url_type = BASE_URL + 'ajax/map/location_detail'
    $.ajax(
      type: 'post'
      url: url_type
      data: 'id=' + id + '&_token=' + $('[name="csrf_token"]').attr('content')
      dataType: 'json').done (data) ->
    if type == 'basic'
      local.setInfoPanel data
    else if type == 'detail'
      local.setModalPanel data, '.modal-width'
    return
    return

  local.setInfoPanel = (data) ->
    $('.info_hover .panel-body').html data.content
    $('.info_hover .panel-title').html data.title
    $('.info_hover').css 'display', 'block'
    return

  local.setModalPanel = (data, type) ->
    $(type + ' .panel-title').text data.title
    $(type + ' .modal-text').html data.content
    $.magnificPopup.open
      items: src: type
      type: 'inline'
      height: '100%'
      preloader: false
      modal: true
      alignTop: true
    return

  local.setContentBlockPanel = (data) ->
    $('.content-block').show()
    $('.content-block .panel-title').text data.title
    $('.content-block .modal-wrapper').html data.content
    return

  local.getRandomRange = (from, to, fixed) ->
    (Math.random() * (to - from) + from).toFixed(fixed) * 1

  local.getRandomViewMap = ->
    lat = local.getRandomRange(-85, 85, 3)
    lon = local.getRandomRange(-140, 140, 3)
    map.panTo new (L.LatLng)(lat, lon, 4)
    map.invalidateSize()
    return

  local.layerInfo = ->

    layerControl.onAdd = (map) ->
      @_div = L.DomUtil.create('div', 'info_hover')
      @update()
      @_div

    layerControl.update = (props) ->
      @_div.innerHTML = '<section class="panel panel-featured panel-featured-success"> <header class="panel-heading"> <div class="panel-actions"> </div><h2 class="panel-title"> </h2></header><div class="panel-body"></div></section>'
      return

    layerControl.addTo map
    return

  local.layerFeatureStyle = (feature) ->
    fill_color = null
    type = local.getFilterId()
    if type.toString().indexOf('thermal') != -1
      if local.getFilter() == 'political' or local.getFilter() == 'relations'
        fill_color = feature.properties.color
      else
        fill_color = local.getColorForPercentage(feature.properties.color / 25, feature.properties.color_group)
    else
      if parseInt(feature.properties.is_owned) == 1
        fill_color = '#0c9700'
        if parseInt(feature.properties.is_capital) == 1
          capital = L.AwesomeMarkers.icon(
            icon: 'star'
            markerColor: 'green')
          L.marker([
            feature.properties.lat
            feature.properties.lon
          ], icon: capital).addTo map
      else
        fill_color = feature.properties.color
    {
      weight: layerFillWeight
      opacity: LayerFillTextOpacity
      color: fill_color
      dashArray: layerFillDashArray
      fillOpacity: layerFillOpacity
      fillColor: fill_color
    }

  local.layerFeatureHighlight = (e) ->
    layer = e.target
    fillColor = 'white'
    if !L.Browser.ie and !L.Browser.opera
      layer.bringToFront()
    $('.info_hover .panel-body').html ''
    if local.getGameType() == 1
# wizard
      local.setTimeOutLocationInfo layer.feature.properties.id, 'basic'
      fillColor = '#69a22d'
    else if local.getGameType() == 2
# game
      local.setTimeOutNationInfo layer.feature.properties.id, 'basic'
    else if local.getGameType() == 3
# war mode
    else
    if parseInt(layer.feature.properties.is_owned) == 1
      fillColor = '#69a22d'
    else if parseInt(layer.feature.properties.is_owned) == 0
      fillColor = '#ff1826'
    layer.setStyle
      weight: layerFillWeight
      color: fillColor
      dashArray: layerFillDashArray
      fillOpacity: layerFillOpacity
      fillColor: fillColor
    return

  local.layerFeatureClick = (e) ->
    layer = e.target
    layer.setStyle
      weight: layerFillWeight
      color: layerFillTextColor
      dashArray: layerFillDashArray
      fillOpacity: layerFillOpacity
      fillColor: layerFillTextColor
    if !L.Browser.ie and !L.Browser.opera
      layer.bringToFront()
    $('.info_hover .panel-body').html ''
    local.contextMenuInit layer
    return

  local.contextMenuInit = (layer) ->
    if local.getGameType() == 1
# wizard
      local.getLocationInfo layer.feature.properties.id, 'detail'
    else if gameType == 2
# game
      if parseFloat(layer.feature.properties.is_thermal) == 1
        toolsModule.enableContextMenu layer.feature, 'own'
      else
        if parseFloat(layer.feature.properties.is_owned) == 1
          toolsModule.enableContextMenu layer.feature, 'own'
        else if parseFloat(layer.feature.properties.is_owned) == 0
          toolsModule.enableContextMenu layer.feature, 'normal'
    else if local.getGameType() == 3
# war mode
      if parseFloat(layer.feature.properties.is_owned) != 1
#toolsModule.enableContextMenu(layer.feature, 'war')
        $.ajax(
          type: 'post'
          url: BASE_URL + 'ajax/warmode/index'
          data:
            'id': layer.feature.properties.id
            '_token': _token
          dataType: 'json').done (data) ->
        local.setModalPanel data, '.modal-width'
        return
    else if local.getGameType() == 4
# war planner
      toolsModule.enableContextMenu layer.feature, 'planner'
    return

  local.styleThermal = (feature) ->
    {
      weight: 2
      opacity: 1
      color: 'white'
      dashArray: '3'
      fillOpacity: 0.8
      fillColor: local.getColorThermal(feature.properties.color)
    }

  local.layerFeatureHighlightReset = (e) ->
    layerGeoJson.resetStyle e.target
    clearTimeout timerInfo
    layerControl.update()
    $('.info_hover').hide()
    return

  local.layerFeatureZoomTo = (e) ->
    map.fitBounds e.target.getBounds()
    return

  local.layerMapZoomTo = (lat, lng, zoom) ->
#map.invalidateSize();
    map.panTo new (L.LatLng)(lat, lng, zoom)
    map.zoomIn zoom
    map.invalidateSize()
    return

  local.layerOnEachFeature = (feature, layer) ->
    layer.on
      mouseover: local.layerFeatureHighlight
      mouseout: local.layerFeatureHighlightReset
      click: local.layerFeatureClick
    return

  local.setTimeOutNationInfo = (id, type) ->
    local.getNationInfo id, type
    return

  local.setTimeOutLocationInfo = (id, type) ->
    clearTimeout location_info_timeout
    location_info_timeout = setTimeout((->
      local.getLocationInfo id, type
      return
    ), 1500)
    return

  local.setIntervalJson = ->
    setInterval local.getRandomViewMap, 30000
    return

  local.hideContextMenu = ->
    if local.getGameType() > 1
      $('#rightclick').contextMenu 'hide'
      $('#rightclick-1').contextMenu 'hide'
      $('#rightclick-2').contextMenu 'hide'
    $('.info_hover').hide()
    return

  local.isWarMode = (status) ->
    local.hideContextMenu()
    if status
      $('.btn_warmode').remove()
      $('.btn_normalmode').remove()
      $('.btn_gotocapital').remove()
      $('.btn_globemode').remove()
      local.modeNormalButton()
      local.modeHomeButton()
      local.modeCompareButton()
      local.setGameType 3
      local.setMaxZoom 13
      local.setMapType 'war'
      local.enableWarInteraction false
      $('.header-warmode').show()
      $('.sidebar-normal').hide()
      $('.page-header').hide()
    else
      $('.btn_warmode').remove()
      $('.btn_normalmode').remove()
      $('.btn_comparemode').remove()
      $('.btn_gotocapital').remove()
      local.modeWarButton()
      local.modeHomeButton()
      #local.modeGlobeButton();
      local.setGameType 2
      local.setMaxZoom 8
      local.setMapType 'world'
      local.enableInteraction true
      $('.sidebar-normal').show()
      $('.page-header').show()
      $('.header-warmode').hide()
    sbs_exists = local.destroyComparison(sbs_exists)
    local.initializeLayerOnly()
    map.invalidateSize()
    local.setFilter 'nations'
    return

  local.enableComparison = ->
    sbs_layer = L.layerGroup()
    layer_comparison_1 = L.tileLayer('https://a.maps.owm.io/map/clouds_new/{z}/{x}/{y}?{appid}',
      noWrap: false
      appid: 'appid=b1b15e88fa797225412429c1c50c122a1').addTo(map)
    layer_comparison_2 = L.tileLayer('https://a.maps.owm.io/map/temp_new/{z}/{x}/{y}?{appid}',
      noWrap: false
      appid: 'appid=b1b15e88fa797225412429c1c50c122a1').addTo(map)
    sbs = L.control.sideBySide(layer_comparison_1, layer_comparison_2).addTo(map)
    sbs_exists = local.destroyComparison(sbs_exists)
    return

  local.destroyComparison = (status) ->
    if status
      local.initializeLayerOnly()
      $('.leaflet-sbs').remove()
      sbs_exists = false
    else
      sbs_exists = true
    sbs_exists

  local.disableGeoJsonLayer = ->
    map.removeLayer layerGeoJson
    return

  local.disablePluginCoordinates = ->
    map.removeControl mapCoordinates
    return

  local.disablePluginMiniMap = ->
    layerMiniMap.removeFrom map
    return

  local.getColor = (value) ->
#value from 0 to 1
    hue = ((1 - value) * 120).toString(10)
    [
      'hsl('
      hue
      ',100%,50%)'
    ].join ''

  local.getColorForPercentage = (pct, group) ->
    percentColors = Red2Green
    if group == 'r2g'
      percentColors = Red2Green
    else if group == 'g2r'
      percentColors = Green2Red
    i = 1
    while i < percentColors.length - 1
      if pct < percentColors[i].pct
        break
      i++
    lower = percentColors[i - 1]
    upper = percentColors[i]
    range = upper.pct - (lower.pct)
    rangePct = (pct - (lower.pct)) / range
    pctLower = 1 - rangePct
    pctUpper = rangePct
    color =
      r: Math.floor(lower.color.r * pctLower + upper.color.r * pctUpper)
      g: Math.floor(lower.color.g * pctLower + upper.color.g * pctUpper)
      b: Math.floor(lower.color.b * pctLower + upper.color.b * pctUpper)
    'rgb(' + [
      color.r
      color.g
      color.b
    ].join(',') + ')'
  # or output as hex if preferred

  local.getColorThermal = (d) ->
    if d > 100 then '#800026' else if d > 90 then '#BD0026' else if d > 80 then '#E31A1C' else if d > 70 then '#FC4E2A' else if d > 50 then '#FD8D3C' else if d > 25 then '#FEB24C' else if d > 10 then '#FED976' else '#FFEDA0'

  local.getColorResource = (d) ->
    colors = [
      '7e1e9c'
      '15b01a'
      '0343df'
      'ff81c0'
      '653700'
      'e50000'
      '95d0fc'
      'f97306'
      'c20078'
      'ffff14'
      '929591'
      'bf77f6'
      '9a0eea'
      '033500'
      '06c2ac'
      '13eac9'
      '650021'
      '6e750e'
      '06470c'
      'ff796c'
      'e6daa6'
      '001146'
      'cea2fd'
      '000000'
      '677a04'
      '380282'
      'ceb301'
      'c04e01'
      '0165fc'
      '8e82fe'
      'FF0000'
    ]
    '#' + colors[d]

  local.setFilter = (value) ->
    filterKey = value
    return

  local.getFilter = ->
    filterKey

  local.setFilterId = (value) ->
    filterId = value
    return

  local.getFilterId = ->
    filterId

  local.setGameType = (value) ->
    gameType = value
    return

  local.getGameType = ->
    gameType

  local.setMapType = (value) ->
    mapType = value
    return

  local.getMapType = ->
    mapType

  local.setMaxZoom = (value) ->
    mapMaxZoom = value
    return

  local.getMaxZoom = ->
    mapMaxZoom

  local.setIsWizard = (key) ->
    isWizard = key
    return

  local.getIsWizard = ->
    isWizard

  local.setIsInteractive = (key) ->
    isInteractive = key
    return

  local.getIsInteractive = ->
    isInteractive

  local.setMapId = (key) ->
    mapId = key
    return

  local.getMapId = ->
    mapId

  local.setNationId = (key) ->
    nationId = key
    return

  local.getNationId = ->
    nationId

  local.generateMesh = ->
    width = 960
    height = 500
    radius = 20
    topology = hexTopology(radius, width, height)
    projection = hexProjection(radius)
    path = d3.geoPath().projection(projection)
    svg = d3.select('.leaflet-clickable').append('svg').attr('width', width).attr('height', height)

    mousedown = (d) ->
      mousing = if d.fill then -1 else +1
      mousemove.apply this, arguments
      return

    mousemove = (d) ->
      if mousing
        d3.select(this).classed 'fill', d.fill = mousing > 0
        border.call redraw
      return

    mouseup = ->
      mousemove.apply this, arguments
      mousing = 0
      return

    redraw = (border) ->
      border.attr 'd', path(topojson.mesh(topology, topology.objects.hexagons, (a, b) ->
        a.fill ^ b.fill
      ))
      return

    hexTopology = (radius, width, height) ->
      `var j`
      `var i`
      dx = radius * 2 * Math.sin(Math.PI / 3)
      dy = radius * 1.5
      m = Math.ceil((height + radius) / dy) + 1
      n = Math.ceil(width / dx) + 1
      geometries = []
      arcs = []
      j = -1
      while j <= m
        i = -1
        while i <= n
          y = j * 2
          x = (i + (j & 1) / 2) * 2
          arcs.push [
            [
              x
              y - 1
            ]
            [
              1
              1
            ]
          ], [
            [
              x + 1
              y
            ]
            [
              0
              1
            ]
          ], [
            [
              x + 1
              y + 1
            ]
            [
              -1
              1
            ]
          ]
          ++i
        ++j
      j = 0
      q = 3
      while j < m
        i = 0
        while i < n
          geometries.push
            type: 'Polygon'
            arcs: [ [
              q
              q + 1
              q + 2
              ~(q + (n + 2 - (j & 1)) * 3)
              ~(q - 2)
              ~(q - ((n + 2 + (j & 1)) * 3) + 2)
            ] ]
            fill: Math.random() > i / n * 2
          ++i
          q += 3
        ++j
        q += 6
      {
        transform:
          translate: [
            0
            0
          ]
          scale: [
            1
            1
          ]
        objects: hexagons:
          type: 'GeometryCollection'
          geometries: geometries
        arcs: arcs
      }

    hexProjection = (radius) ->
      dx = radius * 2 * Math.sin(Math.PI / 3)
      dy = radius * 1.5
      { stream: (stream) ->
        {
          point: (x, y) ->
            stream.point x * dx / 2, (y - ((2 - (y & 1)) / 3)) * dy / 2
            return
          lineStart: ->
            stream.lineStart()
            return
          lineEnd: ->
            stream.lineEnd()
            return
          polygonStart: ->
            stream.polygonStart()
            return
          polygonEnd: ->
            stream.polygonEnd()
            return

        }
      }

    svg.append('g').attr('class', 'hexagon').selectAll('path').data(topology.objects.hexagons.geometries).enter().append('path').attr('d', (d) ->
      path topojson.feature(topology, d)
    ).attr('class', (d) ->
      if d.fill then 'fill' else null
    ).on('mousedown', mousedown).on('mousemove', mousemove).on 'mouseup', mouseup
    svg.append('path').datum(topojson.mesh(topology, topology.objects.hexagons)).attr('class', 'mesh').attr 'd', path
    border = svg.append('path').attr('class', 'border').call(redraw)
    mousing = 0
    return

  local.projectPoint = (x, y) ->
    point = map.latLngToLayerPoint(new (L.LatLng)(y, x))
    @stream.point point.x, point.y
    return

  return
) exports
