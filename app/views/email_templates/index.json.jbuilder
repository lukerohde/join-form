json.array!(@email_templates) do |email_template|
  json.extract! email_template, :id, :subject, :body_html, :css, :body_plain, :attachment
  json.url email_template_url(email_template, format: :json)
end
