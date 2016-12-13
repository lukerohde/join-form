class AddPageTitleToJoinForm < ActiveRecord::Migration[5.0]
  def change
    add_column :join_forms, :page_title, :string
  end
end
