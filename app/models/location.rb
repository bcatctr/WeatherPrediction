class Location < ActiveRecord::Base
  has_many :weathers
  has_many :location_predictions
  belongs_to :post_code
end
