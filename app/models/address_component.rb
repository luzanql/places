class AddressComponent

	attr_reader :long_name, :short_name, :types

	def initialize (params={})
	 @long_name=params[:long_name].to_s	
	 @short_name=params[:short_name].to_s
	 @types=params[:types]	
	end 
end