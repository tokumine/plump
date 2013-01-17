# Original python code Copyright (c) 2008 Klokan Petr Pridal. All rights reserved.

class GlobalMercator
  #   def __init__(self, tileSize=256):
  #   "Initialize the TMS Global Mercator pyramid"
  #   self.tileSize = tileSize
  #   self.initialResolution = 2 * math.pi * 6378137 / self.tileSize
  #   # 156543.03392804062 for tileSize 256 pixels
  #   self.originShift = 2 * math.pi * 6378137 / 2.0
  #   # 20037508.342789244
  # 
  def initialize (tile_size=256)
    @tile_size = tile_size
    @initial_resolution = 2 * Math::PI * 6378137 / @tile_size
    @origin_shift = 2 * Math::PI * 6378137 / 2.0
  end

  # def LatLonToMeters(self, lat, lon ):
  #   "Converts given lat/lon in WGS84 Datum to XY in Spherical Mercator EPSG:900913"
  # 
  #   mx = lon * self.originShift / 180.0
  #   my = math.log( math.tan((90 + lat) * math.pi / 360.0 )) / (math.pi / 180.0)
  # 
  #   my = my * self.originShift / 180.0
  #   return mx, my
  # 
  def lat_long_to_meters (lat, lon)
    mx = lon * @origin_shift / 180.0
    my = Math.log( Math.tan((90 + lat) * Math::PI / 360.0 )) / (Math::PI / 180.0)
  
    my = my * @origin_shift / 180.0
    return mx, my
  end

  # def MetersToLatLon(self, mx, my ):
  #   "Converts XY point from Spherical Mercator EPSG:900913 to lat/lon in WGS84 Datum"
  # 
  #   lon = (mx / self.originShift) * 180.0
  #   lat = (my / self.originShift) * 180.0
  # 
  #   lat = 180 / math.pi * (2 * math.atan( math.exp( lat * math.pi / 180.0)) - math.pi / 2.0)
  #   return lat, lon
  def meters_to_lat_lon (mx, my)
    lon = (mx / @origin_shift) * 180.0
    lat = (my / @origin_shift) * 180.0
  
    lat = 180 / Math::PI * (2 * Math.atan( Math.exp( lat * Math::PI / 180.0)) - Math::PI / 2.0)
    return lat, lon
  end

  # def PixelsToMeters(self, px, py, zoom):
  #   "Converts pixel coordinates in given zoom level of pyramid to EPSG:900913"
  # 
  #   res = self.Resolution( zoom )
  #   mx = px * res - self.originShift
  #   my = py * res - self.originShift
  #   return mx, my
  #
  def pixels_to_meters (px, py, zoom)
    res = resolution( zoom )
    mx = px * res - @origin_shift
    my = py * res - @origin_shift
    return mx, my
  end

  # def MetersToPixels(self, mx, my, zoom):
  #   "Converts EPSG:900913 to pyramid pixel coordinates in given zoom level"
  #       
  #   res = self.Resolution( zoom )
  #   px = (mx + self.originShift) / res
  #   py = (my + self.originShift) / res
  #   return px, py
  # 
  def meters_to_pixels (mx, my, zoom)
    res = resolution( zoom )
    px = (mx + @origin_shift) / res
    py = (my + @origin_shift) / res
    return px, py
  end

  # def PixelsToTile(self, px, py):
  #   "Returns a tile covering region in given pixel coordinates"
  # 
  #   tx = int( math.ceil( px / float(self.tileSize) ) - 1 )
  #   ty = int( math.ceil( py / float(self.tileSize) ) - 1 )
  #   return tx, ty
  # 
  def pixels_to_tile (px, py)
    tx = ( px / @tile_size.to_f ).ceil.to_i - 1
    ty = ( py / @tile_size.to_f ).ceil.to_i - 1
    return tx, ty
  end

  # def PixelsToRaster(self, px, py, zoom):
  #   "Move the origin of pixel coordinates to top-left corner"
  #   
  #   mapSize = self.tileSize << zoom
  #   return px, mapSize - py
  #   
  def pixels_to_raster (px, py, zoom)
    mapSize = @tile_size << zoom
    return px, mapSize - py
  end

  # def MetersToTile(self, mx, my, zoom):
  #   "Returns tile for given mercator coordinates"
  #   
  #   px, py = self.MetersToPixels( mx, my, zoom)
  #   return self.PixelsToTile( px, py)
  # 
  def meters_to_tile (mx, my, zoom)
    px, py = meters_to_pixels( mx, my, zoom)
    return pixels_to_tile( px, py)
  end
  # def TileBounds(self, tx, ty, zoom):
  #   "Returns bounds of the given tile in EPSG:900913 coordinates"
  #   
  #   minx, miny = self.PixelsToMeters( tx*self.tileSize, ty*self.tileSize, zoom )
  #   maxx, maxy = self.PixelsToMeters( (tx+1)*self.tileSize, (ty+1)*self.tileSize, zoom )
  #   return ( minx, miny, maxx, maxy )
  # 
  def tile_bounds (tx, ty, zoom)
    minx, miny = pixels_to_meters( tx * @tile_size, ty * @tile_size, zoom )
    maxx, maxy = pixels_to_meters( (tx+1) * @tile_size, (ty+1) * @tile_size, zoom )
    return [minx, miny, maxx, maxy]
  end
  # def TileLatLonBounds(self, tx, ty, zoom ):
  #   "Returns bounds of the given tile in latutude/longitude using WGS84 datum"
  # 
  #   bounds = self.TileBounds( tx, ty, zoom)
  #   minLat, minLon = self.MetersToLatLon(bounds[0], bounds[1])
  #   maxLat, maxLon = self.MetersToLatLon(bounds[2], bounds[3])
  #    
  #   return ( minLat, minLon, maxLat, maxLon )
  #   
  def tile_lat_lon_bounds (tx, ty, zoom)
    bounds = tile_bounds( tx, ty, zoom )
    minLat, minLon = meters_to_lat_lon(bounds[0], bounds[1])
    maxLat, maxLon = meters_to_lat_lon(bounds[2], bounds[3])
     
    return [minLat, minLon, maxLat, maxLon]
  end

  # def Resolution(self, zoom ):
  #   "Resolution (meters/pixel) for given zoom level (measured at Equator)"
  #   
  #   # return (2 * math.pi * 6378137) / (self.tileSize * 2**zoom)
  #   return self.initialResolution / (2**zoom)
  #   
  def resolution (zoom)
    @initial_resolution / (2**zoom)
  end
  # def ZoomForPixelSize(self, pixelSize ):
  #   "Maximal scaledown zoom of the pyramid closest to the pixelSize."
  #   
  #   for i in range(30):
  #     if pixelSize > self.Resolution(i):
  #       return i-1 if i!=0 else 0 # We don't want to scale up
  # 
  def zoom_for_pixel_size (pixel_size)
    # TODO double check this
    (1..30).each do |i|
      if pixel_size > resolution(i)
        return (i != 0) ? (i - 1) : 0
      end
    end
  end
  # def GoogleTile(self, tx, ty, zoom):
  #   "Converts TMS tile coordinates to Google Tile coordinates"
  #   
  #   # coordinate origin is moved from bottom-left to top-left corner of the extent
  #   return tx, (2**zoom - 1) - ty
  # 
  def google_tile (tx, ty, zoom)
    [tx, (2**zoom - 1) - ty]
  end
  # def QuadTree(self, tx, ty, zoom ):
  #   "Converts TMS tile coordinates to Microsoft QuadTree"
  #   
  #   quadKey = ""
  #   ty = (2**zoom - 1) - ty
  #   for i in range(zoom, 0, -1):
  #     digit = 0
  #     mask = 1 << (i-1)
  #     if (tx & mask) != 0:
  #       digit += 1
  #     if (ty & mask) != 0:
  #       digit += 2
  #     quadKey += str(digit)
  #     
  #   return quadKey
  # 
  def quad_tree (tx, ty, zoom)
    quad_key = ''
    ty = (2**zoom - 1) - ty
    i = zoom
    while i > 0 do
      digit = 0
      mask = 1 << (i-1)
      digit += 1 if (tx & mask) != 0
      digit += 2 if (ty & mask) != 0
      quad_key += digit.to_s
      i -= 1
    end
    quad_key
  end
end

class GlobalGeodetic
  #   def __init__(self, tileSize = 256):
  #   self.tileSize = tileSize
  # 
  def initialize (tile_size=256)
    @tile_size = tile_size
  end
  # def LatLonToPixels(self, lat, lon, zoom):
  #   "Converts lat/lon to pixel coordinates in given zoom of the EPSG:4326 pyramid"
  # 
  #   res = 180 / 256.0 / 2**zoom
  #   px = (180 + lat) / res
  #   py = (90 + lon) / res
  #   return px, py
  # 
  def lat_lon_to_pixels (lat, lon, zoom)
    res = 180 / 256.0 / 2**zoom
    px = (180 + lat) / res
    py = (90 + lon) / res
    return [px, py]
  end
  # def PixelsToTile(self, px, py):
  #   "Returns coordinates of the tile covering region in pixel coordinates"
  # 
  #   tx = int( math.ceil( px / float(self.tileSize) ) - 1 )
  #   ty = int( math.ceil( py / float(self.tileSize) ) - 1 )
  #   return tx, ty
  # 
  def pixels_to_tile (px, py)
    tx = (( px / @tile_size.to_f ).ceil - 1 ).to_i
    ty = (( py / @tile_size.to_f ).ceil - 1 ).to_i
    return tx, ty
  end
  # def Resolution(self, zoom ):
  #   "Resolution (arc/pixel) for given zoom level (measured at Equator)"
  #   
  #   return 180 / 256.0 / 2**zoom
  #   #return 180 / float( 1 << (8+zoom) )
  # 
  def resolution (zoom)
    return 180 / 256.0 / 2**zoom
  end
  # def TileBounds(tx, ty, zoom):
  #   "Returns bounds of the given tile"
  #   res = 180 / 256.0 / 2**zoom
  #   return (
  #     tx*256*res - 180,
  #     ty*256*res - 90,
  #     (tx+1)*256*res - 180,
  #     (ty+1)*256*res - 90
  #   )
  def tile_bounds (tx, ty, zoom)
    res = 180 / 256.0 / 2**zoom
    return [
      tx*256*res - 180,
      ty*256*res - 90,
      (tx+1)*256*res - 180,
      (ty+1)*256*res - 90
    ]
  end
end

# if __name__ == "__main__":
#   import sys, os

if $PROGRAM_NAME == __FILE__

#     
#   def Usage(s = ""):
#     print "Usage: globalmaptiles.py [-profile 'mercator'|'geodetic'] zoomlevel lat lon [latmax lonmax]"
#     print
#     if s:
#       print s
#       print
#     print "This utility prints for given WGS84 lat/lon coordinates (or bounding box) the list of tiles"
#     print "covering specified area. Tiles are in the given 'profile' (default is Google Maps 'mercator')"
#     print "and in the given pyramid 'zoomlevel'."
#     print "For each tile several information is printed including bonding box in EPSG:900913 and WGS84."
#     sys.exit(1)
# 
  def usage (s=nil)
    puts "Usage: global_map_tiles.rb [-profile 'mercator'|'geodetic'] zoomlevel lat lon [latmax lonmax]"
    puts
    if s
      puts s
      puts ''
    end
    puts "This utility prints for given WGS84 lat/lon coordinates (or bounding box) the list of tiles"
    puts "covering specified area. Tiles are in the given 'profile' (default is Google Maps 'mercator')"
    puts "and in the given pyramid 'zoomlevel'."
    puts "For each tile several information is printed including bonding box in EPSG:900913 and WGS84."
    exit 1
  end

#   profile = 'mercator'
#   zoomlevel = None
#   lat, lon, latmax, lonmax = None, None, None, None
#   boundingbox = False

  profile = 'mercator'
  zoomlevel = nil
  lat, lon, latmax, lonmax = nil, nil, nil, nil
  boundingbox = false

  #   argv = sys.argv
  #   i = 1
  #   while i < len(argv):
  #     arg = argv[i]
  # 
  #     if arg == '-profile':
  #       i = i + 1
  #       profile = argv[i]
  #     
  #     if zoomlevel is None:
  #       zoomlevel = int(argv[i])
  #     elif lat is None:
  #       lat = float(argv[i])
  #     elif lon is None:
  #       lon = float(argv[i])
  #     elif latmax is None:
  #       latmax = float(argv[i])
  #     elif lonmax is None:
  #       lonmax = float(argv[i])
  #     else:
  #       Usage("ERROR: Too many parameters")
  # 
  #     i = i + 1
  #   

  argv = ARGV
  i = 0
  while i < argv.length
    arg = argv[i]

    if arg == '-profile'
      i = i + 1
      profile = argv[i]
    end
    
    if zoomlevel.nil?
      zoomlevel = argv[i].to_i
    elsif lat.nil?
      lat = argv[i].to_f
    elsif lon.nil?
      lon = argv[i].to_f
    elsif latmax.nil?
      latmax = argv[i].to_f
    elsif lonmax.nil?
      lonmax = argv[i].to_f
    else
      usage("ERROR: Too many parameters")
    end

    i += 1
  end

#   if profile != 'mercator':
#     Usage("ERROR: Sorry, given profile is not implemented yet.")
#   
  if profile != 'mercator'
    usage("ERROR: Sorry, given profile is not implemented yet.")
  end
  
#   if zoomlevel == None or lat == None or lon == None:
#     Usage("ERROR: Specify at least 'zoomlevel', 'lat' and 'lon'.")
#   if latmax is not None and lonmax is None:
#     Usage("ERROR: Both 'latmax' and 'lonmax' must be given.")
#   
  if zoomlevel == nil or lat == nil or lon == nil
    usage("ERROR: Specify at least 'zoomlevel', 'lat' and 'lon'.")
  end
  if latmax != nil and lonmax == nil
    usage("ERROR: Both 'latmax' and 'lonmax' must be given.")
  end
  
#   if latmax != None and lonmax != None:
#     if latmax < lat:
#       Usage("ERROR: 'latmax' must be bigger then 'lat'")
#     if lonmax < lon:
#       Usage("ERROR: 'lonmax' must be bigger then 'lon'")
#     boundingbox = (lon, lat, lonmax, latmax)
#   
  if latmax != nil and lonmax != nil
    if latmax < lat
      usage("ERROR: 'latmax' must be bigger then 'lat'")
    end
    if lonmax < lon
      usage("ERROR: 'lonmax' must be bigger then 'lon'")
    end
    boundingbox = [lon, lat, lonmax, latmax]
  end
  
#   tz = zoomlevel
#   mercator = GlobalMercator()
# 
  tz = zoomlevel
  mercator = GlobalMercator.new

#   mx, my = mercator.LatLonToMeters( lat, lon )
#   print "Spherical Mercator (ESPG:900913) coordinates for lat/lon: "
#   print (mx, my)
#   tminx, tminy = mercator.MetersToTile( mx, my, tz )
#   
  mx, my = mercator.lat_long_to_meters( lat, lon )
  puts "Spherical Mercator (ESPG:900913) coordinates for lat/lon: "
  puts "(#{mx}, #{my})"
  tminx, tminy = mercator.meters_to_tile( mx, my, tz )

#   if boundingbox:
#     mx, my = mercator.LatLonToMeters( latmax, lonmax )
#     print "Spherical Mercator (ESPG:900913) cooridnate for maxlat/maxlon: "
#     print (mx, my)
#     tmaxx, tmaxy = mercator.MetersToTile( mx, my, tz )
#   else:
#     tmaxx, tmaxy = tminx, tminy
#     
  if boundingbox
    mx, my = mercator.lat_long_to_meters( latmax, lonmax )
    puts "Spherical Mercator (ESPG:900913) cooridnate for maxlat/maxlon: "
    puts "(#{mx}, #{my})"
    tmaxx, tmaxy = mercator.meters_to_tile( mx, my, tz )
  else
    tmaxx, tmaxy = tminx, tminy
  end
    
#   for ty in range(tminy, tmaxy+1):
#     for tx in range(tminx, tmaxx+1):
#       tilefilename = "%s/%s/%s" % (tz, tx, ty)
#       print tilefilename, "( TileMapService: z / x / y )"
#     
#       gx, gy = mercator.GoogleTile(tx, ty, tz)
#       print "\tGoogle:", gx, gy
#       quadkey = mercator.QuadTree(tx, ty, tz)
#       print "\tQuadkey:", quadkey, '(',int(quadkey, 4),')'
#       bounds = mercator.TileBounds( tx, ty, tz)
#       print
#       print "\tEPSG:900913 Extent: ", bounds
#       wgsbounds = mercator.TileLatLonBounds( tx, ty, tz)
#       print "\tWGS84 Extent:", wgsbounds
#       print "\tgdalwarp -ts 256 256 -te %s %s %s %s %s %s_%s_%s.tif" % (
#         bounds[0], bounds[1], bounds[2], bounds[3], "<your-raster-file-in-epsg900913.ext>", tz, tx, ty)
#       print
  (tminy..tmaxy).each do |ty|
    (tminx..tmaxx).each do |tx|
      tilefilename = "%s/%s/%s" % [tz, tx, ty]
      puts "#{tilefilename} ( TileMapService: z / x / y )"
    
      gx, gy = mercator.google_tile(tx, ty, tz)
      puts "\tGoogle: #{gx} #{gy}"
      quadkey = mercator.quad_tree(tx, ty, tz)
      puts "\tQuadkey: #{quadkey} ( #{quadkey.to_i(4)} )"
      bounds = mercator.tile_bounds( tx, ty, tz)
      puts ''
      puts "\tEPSG:900913 Extent:  (#{bounds.join(', ')})"
      wgsbounds = mercator.tile_lat_lon_bounds( tx, ty, tz)
      puts "\tWGS84 Extent: (#{wgsbounds.join(', ')})"
      puts "\tgdalwarp -ts 256 256 -te %s %s %s %s %s %s_%s_%s.tif" % [
        bounds[0], bounds[1], bounds[2], bounds[3], "<your-raster-file-in-epsg900913.ext>", tz, tx, ty
      ]
      puts
    end
  end

end # if