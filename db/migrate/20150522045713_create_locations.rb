class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :location_id
      t.float :lat
      t.float :long

      t.timestamps null: false
    end
  end
end
