class AddAddressOnToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :address_on, :boolean, default: true, null: false
  end
end
