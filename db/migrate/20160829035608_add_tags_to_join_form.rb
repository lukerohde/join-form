class AddTagsToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :tags, :string
  end
end
