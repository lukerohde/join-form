class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.string :type
      t.string :subject
      t.text :body_plain
      t.text :body_html
      t.string :delivery_status
      t.integer :sender_id
      t.integer :recipient_id
      t.string :recipient_address
      t.string :sender_address
      t.integer :template_id
      t.integer :parent_id

      t.timestamps null: false
    end
  end
end
