class AddTimeToWeather < ActiveRecord::Migration
  def change
    add_column :weathers, :time, :time
  end
end
