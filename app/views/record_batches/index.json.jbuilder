json.array!(@record_batches) do |record_batch|
  json.extract! record_batch, :id, :name, :email_template_id, :sms_template_id
  json.url record_batch_url(record_batch, format: :json)
end
