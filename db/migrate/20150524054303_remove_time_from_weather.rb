class RemoveTimeFromWeather < ActiveRecord::Migration
  def change
    remove_column :weathers, :time, :date
  end
end
