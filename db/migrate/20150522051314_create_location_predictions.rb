class CreateLocationPredictions < ActiveRecord::Migration
  def change
    create_table :location_predictions do |t|
      t.integer :period
      t.date :time
      t.float :lon
      t.float :lat

      t.timestamps null: false
    end
  end
end
