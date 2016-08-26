json.array!(@records) do |record|
  json.extract! record, :id, :type, :subject, :body_plain, :body_html, :delivery_status, :sender_id, :recipient_id, :recipient, :sender, :template_id, :parent_id
  json.url record_url(record, format: :json)
end
