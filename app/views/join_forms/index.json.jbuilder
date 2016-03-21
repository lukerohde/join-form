json.array!(@join_forms) do |join_form|
  json.extract! join_form, :url, :message_types, :slugs
  json.url join_form_url(join_form, format: :json)
end
