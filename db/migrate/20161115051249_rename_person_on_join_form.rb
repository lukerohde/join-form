class RenamePersonOnJoinForm < ActiveRecord::Migration
  def change
  	rename_column :join_forms, :person_id, :admin_id
  end
end
