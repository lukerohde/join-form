class AddSenderToRecordBatch < ActiveRecord::Migration
  def change
    add_column :record_batches, :sender_id, :integer
    add_column :record_batches, :sender_sms_address, :string
    add_column :record_batches, :sender_email_address, :string
  end
end
