class AddOrganiserIdToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :organiser_id, :int
  end
end
