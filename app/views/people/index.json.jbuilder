json.array!(@people) do |person|
  json.extract! person, :id, :name, :first_name, :last_name, :title, :mobile, :email, :created_at, :updated_at
  json.url person_url(person, format: :json)
end
