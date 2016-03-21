json.array!(@people) do |person|
  json.extract! person, :id, :name, :first_name, :last_name, :title, :address, :mobile, :fax, :email
  json.url person_url(person, format: :json)
end
