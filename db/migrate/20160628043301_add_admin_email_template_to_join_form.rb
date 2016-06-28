class AddAdminEmailTemplateToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :admin_email_template_id, :int
  end
end
