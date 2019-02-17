
require 'pp'
mongo_client = Mongoid::Clients.default

puts "Seed DB: clear photos"
Photo.mongo_client.database.fs.find.each { |photo|
  photo_id = photo[:_id].to_s
  p = Photo.find(photo_id)
  p.destroy
}

puts "Seed DB: clear places"
mongo_client[:places].delete_many()

puts "Seed DB: create index"
mongo_client[:places].indexes.create_one(
  {'geometry.geolocation': Mongo::Index::GEO2DSPHERE}
)

puts "Seed DB: load places"
place_file = File.open("./db/places.json")
Place.load_all(place_file)

puts "Seed DB: load photos"
Dir.glob("./db/image*.jpg") {|f| photo=Photo.new; photo.contents=File.open(f,'rb'); photo.save}

Photo.all.each {|photo| place_id=photo.find_nearest_place_id 1*1609.34; photo.place=place_id; photo.save}
pp Place.all.reject {|pl| pl.photos.empty?}.map {|pl| pl.formatted_address}.sort
