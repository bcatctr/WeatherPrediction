class CreateWeathers < ActiveRecord::Migration
  def change
    create_table :weathers do |t|
      t.date :time
      t.string :date
      t.float :temperature
      t.string :condition
      t.float :windSpeed
      t.float :windDirection
      t.float :rainFall

      t.timestamps null: false
    end
  end
end
