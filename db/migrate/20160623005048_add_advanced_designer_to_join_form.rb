class AddAdvancedDesignerToJoinForm < ActiveRecord::Migration
  def up
    add_column :join_forms, :advanced_designer, :boolean
  	JoinForm.update_all(advanced_designer: true)
  end

  def down
  	remove_column :join_forms, :advanced_designer
  end
end
