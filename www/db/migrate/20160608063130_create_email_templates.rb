class CreateEmailTemplates < ActiveRecord::Migration
  def change
    create_table :email_templates do |t|
      t.string :subject
      t.text :body_html
      t.text :css
      t.text :body_plain
      t.string :attachment

      t.timestamps null: false
    end
  end
end
