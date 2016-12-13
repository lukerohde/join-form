json.array!(@supergroups) do |supergroup|
  json.extract! supergroup, :id, :name, :type, :www
  json.url supergroup_url(supergroup, format: :json)
end
