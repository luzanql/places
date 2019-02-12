require 'exifr/jpeg'

class Photo

	attr_accessor :id, :location  
	attr_writer  :contents


	def self.mongo_client
    	@@db ||= Mongoid::Clients.default
    	#GridfsLoader.mongo_client
 	end

	#########***************************  PHOTO *****************************########
# Add an initialize method in the Photo class that can be used to initialize the instance attributes of 
# Photo from the hash returned from queries like mongo_client.database.fs.fin
	def initialize (params={})
		#:_id=>BSON::ObjectId.from_string(id.to_s)


		@id = params[:_id].nil? ? params[:id] : params[:_id].to_s
		if params[:metadata] and params[:metadata][:location]
			@location = Point.new(params[:metadata][:location])
		else
			@location = nil;
		end
	end

	def persisted?
    	!@id.nil?
 	end

 # check whether the instance is already persisted and do nothing

 	def save
 		#self.class.persisted?

 		#se the exifr gem to extract geolocation information from the jpeg image.
 		if !self.persisted? then
 		
 		geoloc=EXIFR::JPEG.new(@contents).gps
 		
 		description = {}
 		#description[:metadata] = {:location =>  Point.new(:lng=>geoloc.longitude, :lat=>geoloc.latitude)}
 		#Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
 		description[:content_type]="image/jpeg"  
 		description[:metadata] = {}   
 		description[:metadata][:location] =  (Point.new(:lng=>geoloc.longitude, :lat=>geoloc.latitude)).to_hash
 		@location=Point.new(:lng=>geoloc.longitude, :lat=>geoloc.latitude)
 		grid_file = Mongo::Grid::File.new(@contents.read, description)
		id = self.class.mongo_client.database.fs.insert_one(grid_file)
        @id = id.to_s
        @id
 		end
 	end

 	def self.all (offset=0, limit=0)
 		files=[]
     #   result = mongo_client.database.fs.find.skip(offset).limit(limit)
	#	result.each do |foto |files << Photo.new(foto) end

	    mongo_client.database.fs.find.skip(offset).limit(limit).each do |r| 
        files << Photo.new(r) end
  		#result.each do |lugar|lugares << Place.new(lugar) end
  		return files
 	end



 	def self.find(id)
 		#id = {_id:BSON::ObjectId.from_string(id)}
 		# pp Photo.mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(id)).first 
 		f= mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(id.to_s)).first
        return f.nil? ? nil : Photo.new(f)
 	end


end