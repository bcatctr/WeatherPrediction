class AddTimeToWeather < ActiveRecord::Migration
  def change
    add_column :weathers, :time, :datetime
  end
end
