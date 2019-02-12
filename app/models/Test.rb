require_relative '../../config/environment'
#require 'rails_helper'
require 'geo_utils'
require 'place_utils'
require 'place'

class Test

	def self.probar 
		Place.create_indexes
        ref_point = {:type=>"Point", :coordinates=>[-76.61666667, 39.33333333]}
        ref_distance = 1069.4 * 1000
        ref_list = []
        Place.collection.find.each { |p| 
          if (Geo_utils.distance(p[:geometry][:geolocation], ref_point) <= ref_distance)
            ref_list.push(p)
          end
        }
        list_near = Place.near(Point.new(ref_point), ref_distance)
        expect(list_near).to be_a Mongo::Collection::View
        expect(ref_list.count).to eq list_near.count
        list_near.each { |l| 
          expect(l).to be_a BSON::Document
          expect(ref_list).to include(l)
        }  
	end

end