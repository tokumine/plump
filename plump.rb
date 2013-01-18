# encoding: UTF-8
#
# PLUMP. 
# 
# Takes a mbtile with non-existent tile gaps and fills with blank tiles.
#
# It keeps google maps happy by preventing 404's being served from mapbox/tilelive. 
#
# use: ruby plump.rb [MBTILES-FILE]

require 'sqlite3'
require './lib/global_mercator'
require 'digest/md5'
require 'chunky_png'
require 'ruby-progressbar'

bounds     = nil
minzoom    = nil
maxzoom    = nil
tile_start = nil
tile_end   = nil
tile_size  = 256
gm = GlobalMercator.new tile_size

if !ARGV[0] || !ARGV[0].match(/\.mbtiles$/)
  puts "Use: ruby plump.rb [MBTILES-FILE]"
  exit 0
else
  mbtiles = ARGV[0]
end

db = SQLite3::Database.new mbtiles

# optimize DB connection
db.busy_timeout 1000
db.execute("PRAGMA synchronous=0")
db.execute("PRAGMA locking_mode=EXCLUSIVE")
db.execute("PRAGMA journal_mode=DELETE")

# configure 
db.execute( "select count(*) from map" )  { |row| tile_start = row[0] }
db.execute( "select * from metadata where name = 'bounds'" )  { |row| bounds  =  row[1].split(",") }
db.execute( "select * from metadata where name = 'minzoom'" ) { |row| minzoom =  row[1].to_i       }
db.execute( "select * from metadata where name = 'maxzoom'" ) { |row| maxzoom =  row[1].to_i       }

# blank tile + hash => DB
png      = ChunkyPNG::Image.new(tile_size, tile_size, ChunkyPNG::Color::TRANSPARENT).to_blob
hash_key = Digest::MD5.hexdigest(png).to_s
db.execute("INSERT INTO images (tile_data, tile_id) SELECT ?, ? WHERE NOT EXISTS (SELECT 1 FROM images WHERE tile_id = ?)", [SQLite3::Blob.new(png)], hash_key, hash_key)

# latlng => meters
ax, ay, bx, by = bounds[0].to_f, bounds[1].to_f, bounds[2].to_f, bounds[3].to_f   
amx, amy = gm.lat_long_to_meters(ay,ax)
bmx, bmy = gm.lat_long_to_meters(by,bx)

# count total tiles
tiles = 0
(minzoom..maxzoom).each do |tz|  
  apx, apy = gm.meters_to_pixels(amx,amy,tz)
  bpx, bpy = gm.meters_to_pixels(bmx,bmy,tz)
  atx, aty = gm.pixels_to_tile(apx,apy)
  btx, bty = gm.pixels_to_tile(bpx,bpy)
  agtx, agty = gm.google_tile(atx,aty,tz)
  bgtx, bgty = gm.google_tile(btx,bty,tz)
  tiles += ((bgtx-agtx)*(agty-bgty))
end


# start plumping file
pbar = ProgressBar.create(:title => "PLUMPING...", :total => tiles, :format => '  %t | %c/%C tiles |%P%% |%B')
(minzoom..maxzoom).each do |tz|  

  # meters => pixels => tiles
  apx, apy = gm.meters_to_pixels(amx,amy,tz)
  bpx, bpy = gm.meters_to_pixels(bmx,bmy,tz)
  atx, aty = gm.pixels_to_tile(apx,apy)
  btx, bty = gm.pixels_to_tile(bpx,bpy)
  agtx, agty = gm.google_tile(atx,aty,tz)  #<= ain't TMS no more
  bgtx, bgty = gm.google_tile(btx,bty,tz)

  # blank tile link => DB if missing
  (agtx..bgtx).each do |tx|
    (bgty..agty).each do |ty|
      db.execute("INSERT INTO map (zoom_level, tile_column, tile_row, tile_id) 
                 SELECT ?, ?, ?, ?
                 WHERE NOT EXISTS 
                 (SELECT 1 FROM map WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?)", [tz, tx, ty, hash_key, tz, tx, ty])
      pbar.increment
    end
  end
end
pbar.finish

db.execute( "select count(*) from map" )  { |row| tile_end = row[0] }
puts "\n#{mbtiles}: plumped (#{tile_start} => #{tile_end} tiles)"  
