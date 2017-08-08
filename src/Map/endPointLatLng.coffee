_calculateEndPoint = (latlng, dist, degree) ->
# this function is used to find the points of a to b end point
# Calculates great-circle distances between the two points – that is, the shortest distance over the earth’s surface – using the ‘Haversine’ formula.
# https://stackoverflow.com/questions/27928/calculate-distance-between-two-latitude-longitude-points-haversine-formula/27943
  distance = dist * @options.stretch
  d2r = L.LatLng.DEG_TO_RAD
  r2d = L.LatLng.RAD_TO_DEG
  if @options.unit.toLowerCase() == 'km'
    R = 6378.137
    bearing = degree * d2r
    distance = distance / R
    a = Math.acos(Math.cos(distance) * Math.cos((90 - (latlng.lat)) * d2r) + Math.sin((90 - (latlng.lat)) * d2r) * Math.sin(distance) * Math.cos(bearing))
    B = Math.asin(Math.sin(distance) * Math.sin(bearing) / Math.sin(a))
    return new (L.LatLng)(90 - (a * r2d), B * r2d + latlng.lng)
  else if @options.unit.toLowerCase() == 'px'
    source = @_map.latLngToLayerPoint(latlng)
    rad = degree * d2r
    vector = L.point(Math.cos(rad) * distance, Math.sin(rad) * distance)
    target = source.add(vector)
    return @_map.layerPointToLatLng(target)
  else
    throw Error('end point not defined for unit: ' + @options.unit)
  return

calculateArrowArray = (latlng) ->
# calculates the Array for the arrow
# latlng is the position, where the arrow is added
  degree = @_data.angle
  if latlng.length != undefined
    latlng = new (L.LatLng)(latlng)
  edge = @_calculateEndPoint(latlng, @options.head, degree - (@options.degree))
  arr = [
    edge
    latlng
    @_calculateEndPoint(latlng, @options.head, degree + @options.degree)
  ]
  if @options.closing
    arr.push edge
  arr