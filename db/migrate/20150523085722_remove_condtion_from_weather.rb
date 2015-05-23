class RemoveCondtionFromWeather < ActiveRecord::Migration
  def change
    remove_column :weathers, :condition, :string
  end
end
