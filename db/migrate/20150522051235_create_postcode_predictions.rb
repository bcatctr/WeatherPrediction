class CreatePostcodePredictions < ActiveRecord::Migration
  def change
    create_table :postcode_predictions do |t|
      t.integer :period
      t.date :time

      t.timestamps null: false
    end
  end
end
