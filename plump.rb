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
bounds          = nil
minzoom         = nil
maxzoom         = nil
tile_start      = nil
tile_end        = nil
null_tile_start = nil
null_tile_end   = nil
tile_size       = 256
tiles           = 0
gm              = GlobalMercator.new tile_size

if !ARGV[0] || !ARGV[0].match(/\.mbtiles$/)
  puts "Use: ruby plump.rb [MBTILES-FILE]"
  exit 0
else
  mbtiles = ARGV[0]
end

# optimize DB connection
db = SQLite3::Database.new mbtiles
db.busy_timeout 1000
db.execute("PRAGMA synchronous=0")
db.execute("PRAGMA locking_mode=EXCLUSIVE")
db.execute("PRAGMA journal_mode=DELETE")

# configure 
db.execute( "select count(*) from map where tile_id IS NULL" )  { |row| null_tile_start = row[0] }
db.execute( "select count(*) from map" )  { |row| tile_start = row[0] }
db.execute( "select * from metadata where name = 'bounds'" )  { |row| bounds  =  row[1].split(",") }
db.execute( "select * from metadata where name = 'minzoom'" ) { |row| minzoom =  row[1].to_i       }
db.execute( "select * from metadata where name = 'maxzoom'" ) { |row| maxzoom =  row[1].to_i       }

# blank tile + hash => DB + set NULL links to blank image
puts       "Updating #{null_tile_start} NULL tiles..."
png      = ChunkyPNG::Image.new(tile_size, tile_size, ChunkyPNG::Color::TRANSPARENT).to_blob
hash_key = Digest::MD5.hexdigest(png).to_s
db.execute("INSERT INTO images (tile_data, tile_id) SELECT ?, '#{hash_key}' WHERE NOT EXISTS (SELECT 1 FROM images WHERE tile_id = '#{hash_key}')", [SQLite3::Blob.new(png)])
db.execute("UPDATE map SET tile_id = '#{hash_key}' WHERE tile_id IS NULL")

# Check for missing tiles and fill with blank images
# latlng => meters
ax, ay, bx, by = bounds[0].to_f, bounds[1].to_f, bounds[2].to_f, bounds[3].to_f   
amx, amy = gm.lat_long_to_meters(ay,ax)
bmx, bmy = gm.lat_long_to_meters(by,bx)

# find total possible tiles from bounds
(minzoom..maxzoom).each do |tz|  
  apx, apy = gm.meters_to_pixels(amx,amy,tz)
  bpx, bpy = gm.meters_to_pixels(bmx,bmy,tz)
  atx, aty = gm.pixels_to_tile(apx,apy)
  btx, bty = gm.pixels_to_tile(bpx,bpy)
  tiles += ((btx-atx+1)*(bty-aty+1))   
end

# Replace missing tiles with blank link
pbar = ProgressBar.create(:title => "FILL MISSING TILES", :total => tiles, :format => '  %t | %c/%C tiles |%P%% |%B')
(minzoom..maxzoom).each do |tz|  

  # meters => pixels => tiles
  apx, apy = gm.meters_to_pixels(amx,amy,tz)
  bpx, bpy = gm.meters_to_pixels(bmx,bmy,tz)
  atx, aty = gm.pixels_to_tile(apx,apy)
  btx, bty = gm.pixels_to_tile(bpx,bpy)

  # insert missing
  (atx..btx).each do |tx|
    (aty..bty).each do |ty|
      db.execute("INSERT INTO map (zoom_level, tile_column, tile_row, tile_id) 
                 SELECT ?, ?, ?, '#{hash_key}'
                 WHERE NOT EXISTS 
                 (SELECT 1 FROM map WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?)", [tz, tx, ty, tz, tx, ty])
      pbar.increment
    end
  end
end
pbar.finish

puts "VACCUM'ing DB..."
db.execute("VACUUM")
db.execute( "select count(*) from map where tile_id IS NULL" )  { |row| null_tile_end = row[0] }
db.execute( "select count(*) from map" )  { |row| tile_end = row[0] }
puts "\n#{mbtiles} plumped: (#{null_tile_start-null_tile_end} null tiles + #{tile_end-tile_start} missing tiles)"  