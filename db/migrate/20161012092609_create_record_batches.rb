class CreateRecordBatches < ActiveRecord::Migration
  def change
    create_table :record_batches do |t|
      t.string :name
      t.integer :email_template_id
      t.integer :sms_template_id
      t.integer :join_form_id

      t.timestamps null: false
    end
  end
end
