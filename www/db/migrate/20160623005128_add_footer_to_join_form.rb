class AddFooterToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :footer, :text
  end
end
