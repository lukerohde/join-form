class AddWysiwygHeaderFooterToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :wysiwyg_header, :text
    add_column :join_forms, :wysiwyg_footer, :text
  end
end
