class AddPostCodeToLocation < ActiveRecord::Migration
  def change
    add_reference :locations, :postCode, index: true
    add_foreign_key :locations, :postCodes
  end
end
