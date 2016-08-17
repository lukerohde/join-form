json.array!(@sms_templates) do |sms_template|
  json.extract! sms_template, :id, :short_name, :body
  json.url sms_template_url(sms_template, format: :json)
end
