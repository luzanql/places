class Place
	include ActiveModel::Model

	attr_accessor :id, :formatted_address, :location, :address_components

#an initialize method to Place that can set the attributes from a hash with keys _id, 
#address_components,formatted_address, and geometry.geolocation. 
#(Hint: use .to_s to convert a BSON::ObjectId to a
#String and BSON::ObjectId.from_string(s) to convert it back again.)	
	def initialize(params={}) 
	  @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
	  @formatted_address=params[:formatted_address].to_s
	#  @address_components=params[:address_components].map {|a| AddressComponent.new(a)}
	  @address_components = []
	  params[:address_components].nil? ? params[:address_components] :
	  params[:address_components].each do | ac | @address_components << AddressComponent.new(ac) end
	  @location = params[:geometry].nil? ? params[:geometry] :
	  			  Point.new(params[:geometry][:geolocation])

	end

	def persisted? 
		!@id.nil? 
	end


	def self.mongo_client
		Mongoid::Clients.default
	end

	def self.collection
		self.mongo_client["places"]
	end

	def self.load_all(file_path)
		file=File.read(file_path)
    	collection.insert_many(JSON.parse(file))
	end

	def self.find_by_short_name(name)
		#Place.collection.find(:address_components[1]=>name) returns Mongo::Collection::View.
		#collection.find(:address_components["short_name"]=>name) #returns Mongo::Collection::View.
		collection.find({ 'address_components.short_name' => name })
		#result=collection.find(:short_name=>name).first
		#return result.nil? ? nil : result
	end

	#def self.to_places(value)
    #	return value.is_a?(Place) ? value : Place.new(value)
  	#end

  	def self.to_places(value)
  		places = []
		value.each do |p| places << Place.new(p) end
		return places
  	end

  	#accept a single String id as an argument
  	#convert the id to BSON::ObjectId form (Hint: BSON::ObjectId.from_string(s))
  	def self.find(id)
  		result=collection.find(:_id=> BSON::ObjectId(id)).first
  		return result.nil? ? nil : Place.new(result)
  	end

  	
  	#return each document as in instance of a Place within a collection
  	def self.all(offset=0, limit=0)
  		lugares = []
  		result=collection.find().skip(offset).limit(limit)
  		result.each do |lugar|lugares << Place.new(lugar) end
  		return lugares
  	end

  	def destroy
  		self.class.collection
              .find(_id:BSON::ObjectId.from_string(@id))
              .delete_one   
  	end

#########****************Aggregation Framework Queries ************************########
#3
#returns a collection of hash documents with
#address_components and their associated _id, formatted_address and location properties. 

#accept optional sort, offset, and limit parameters

	def self.get_address_components(sort={:_id=>1}, offset=0, limit=nil)

		
		pipeline = []
		pipeline << {:$unwind=>'$address_components'}
		pipeline << {:$project => {_id:true, address_components:true, formatted_address:true, 
			"geometry.geolocation"=>"$geometry.geolocation"
			}}
		pipeline << {:$sort   =>sort}  unless sort.nil?
		pipeline << {:$skip =>offset} unless offset.nil?
		pipeline << {:$limit  =>limit} unless limit.nil?
		#aggregation = collection.aggregate(pipeline)
		
		result = collection.aggregate(pipeline)
	end

	def self.get_country_names
		#create separate documents for address_components.long_name and address_components.types 
		#(Hint: $project and $unwind
		collection.find.aggregate([{:$project=> 
			 {'address_components.long_name': 1, 'address_components.types': 1} },
			 {'$unwind' => '$address_components'},
			 {'$match' => {'address_components.types' => 'country'} },
			 {:$group=>{:_id=>"$address_components.long_name"}}
		]).to_a.map {|r|  r[:_id]}
	end
	

	def self.find_ids_by_country_code(country_code)

		collection.find.aggregate([
			 {'$match' => {'address_components.short_name' => country_code} },
			 {:$project=>{ :_id=>1}}
		]).map {|doc| doc[:_id].to_s}

	end


#########************************Geolocation Queries ************************########
#3

	def self.create_indexes 
		collection.indexes.create_one({"geometry.geolocation"=>Mongo::Index::GEO2DSPHERE})
		#create_indexes must make sure the 2dsphere index is in place for the geometry.geolocation 
		#property (Hint: Mongo::Index::GEO2DSPHERE)
	end

	def self.remove_indexes
		collection.indexes.drop_one("geometry.geolocation_2dsphere")
		#collection.indexes.map {|r| collection.indexes.drop_one(r[:name])}
	end


	#accept an input parameter of type Point (created earlier) 
    def self.near(point, max_meters=nil)
		query={:$geometry=>point.to_hash}
		query[:$maxDistance]= max_meters unless max_meters.nil?
		  collection.find(
			{ "geometry.geolocation"=>
			  { :$near =>
			       query
			  }
			}
		  )
	end


#Create an instance method (also) called near that wraps the class method you just ﬁnished. 
#accept an optional parameter that sets a maximum distance threshold in meters 
	def near(max_meters=nil)

		if max_meters.nil?
			self.class.to_places(self.class.near(location))
		else
			self.class.to_places(self.class.near(location, max_meters))
		end
    	
	end



#########*************************RELATIONSHIP*************************########
#5
def photos(offset=0, limit=0)
    self.class.mongo_client.database.fs.find(
      "metadata.place": BSON::ObjectId.from_string(@id)
    ).map { |photo|
      Photo.new(photo)
    }
end 

=begin

def photos(offset=0, limit=nil)
    photos = []

    if !limit.nil?
      Photo.find_photos_for_place(@id).aggregate([
                                         {:$skip=>offset},
                                         {:$limit=> limit}
                                     ]).each {|doc| photos << Photo.new(doc)}
    else
      Photo.find_photos_for_place(@id).aggregate([
                                         {:$skip=> offset}
                                     ]).each {|doc| photos << Photo.new(doc)}
    end

    photos
  end

=end


end