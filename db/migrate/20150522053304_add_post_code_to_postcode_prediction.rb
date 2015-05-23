class AddPostCodeToPostcodePrediction < ActiveRecord::Migration
  def change
    add_reference :postcode_predictions, :postCode, index: true
    add_foreign_key :postcode_predictions, :postCodes
  end
end
