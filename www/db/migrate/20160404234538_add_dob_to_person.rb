class AddDobToPerson < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :dob, :date
  end
end
