class AddLocationToLocationPrediction < ActiveRecord::Migration
  def change
    add_reference :location_predictions, :location, index: true
    add_foreign_key :location_predictions, :locations
  end
end
