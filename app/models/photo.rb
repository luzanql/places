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

 	 # check whether the instance is already persisted and do nothing

 	def save
 		if self.persisted? then
 			#self.class.mongo_client.database.fs.find(:_id=> BSON::ObjectId.from_string(@id))
 			#.update_one({"location"=>  @location.to_hash})
 			self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId(@id)).
 			update_one(:$set=>{'metadata.location'=>self.location.to_hash})
 		else	
 		geoloc=EXIFR::JPEG.new(@contents).gps
 		
 		description = {}	
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

 	# Create a custom getter for contents that will return the data contents of the ﬁle. This method must: 
 	def contents
 		stored_file = Photo.mongo_client.database.fs.find_one(_id: BSON::ObjectId.from_string(@id))
		foto = Photo.find(@id)
		contents = ""

		stored_file.chunks.reduce([]) { |x, chunk|
			contents << chunk.data.data
		}
		nf = File.open("./db/output.jpg", "wb") { |file| file.write(@contents) }
		contents
 	end

 	#Add an instance method called destroy to the Photo class that will delete the ﬁle and contents
 	# associated with the ID of the object instance. This method must:
 	def destroy
 		#Photo.all.each {|photo| photo.destroy }
    	self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(self.id)).delete_one
  	end


  	################################## RELATIONSHIPS ##########################################
  	
	def find_nearest_place_id(max_distance)
		id = near_places = Place.near(@location, max_distance).aggregate([
			{:$project=>{'_id': 1}},
			{:$limit=> 1}
		]).to_a.map {|r|  r[:_id]}

		if id.nil?
			nil
		else
			id.first
		end

	end


end