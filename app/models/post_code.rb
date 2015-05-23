class PostCode < ActiveRecord::Base
  has_many :locations
  has_many :postcode_predictions
end
