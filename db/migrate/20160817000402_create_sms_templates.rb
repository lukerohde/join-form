class CreateSmsTemplates < ActiveRecord::Migration
  def change
    create_table :sms_templates do |t|
      t.string :short_name
      t.text :body

      t.timestamps null: false
    end
  end
end
