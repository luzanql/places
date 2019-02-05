class Point

	attr_accessor :longitude, :latitude

	def to_hash
	  geoJsonPoint = { type: "Point", coordinates: [ @longitude, @latitude ] }
	end

	#set the attributes from a hash with keys lat and lng or GeoJSON Point format	
	def initialize(params={}) 
	 	if params[:coordinates]
      		@longitude=params[:coordinates][0]
      		@latitude=params[:coordinates][1]
    	else 
      		@longitude=params[:lng]
      		@latitude=params[:lat]
    	end
	end



end