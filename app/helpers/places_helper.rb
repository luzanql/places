module PlacesHelper
	def to_places(value)
    return value.is_a?(Place) ? value : Place.new(value)
  end
end