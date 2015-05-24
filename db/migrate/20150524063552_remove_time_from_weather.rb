class RemoveTimeFromWeather < ActiveRecord::Migration
  def change
    remove_column :weathers, :time, :time
  end
end
