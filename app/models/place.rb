class Place

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

#########***************************  PHOTO *****************************########
#9

#########*************************RELATIONSHIP*************************########
#5

#########*************************DATA POPULATION*************************########
#7

#########*************************SERVER PHOTO IMAGES*************************########
#3

#########**********************Show Places and Photo Images*******************########
#5


end