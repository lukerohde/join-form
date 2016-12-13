class AddGroupIdToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :group_id, :string
  end
end
