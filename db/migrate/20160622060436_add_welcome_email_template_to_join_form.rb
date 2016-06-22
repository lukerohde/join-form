class AddWelcomeEmailTemplateToJoinForm < ActiveRecord::Migration
  def change
    add_reference :join_forms, :welcome_email_template, references: :email_templates, index: true
  	add_foreign_key :join_forms, :email_templates, column: :welcome_email_template_id
  end
end
