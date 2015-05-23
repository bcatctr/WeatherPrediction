class AddLocationToWeather < ActiveRecord::Migration
  def change
    add_reference :weathers, :location, index: true
    add_foreign_key :weathers, :locations
  end
end
