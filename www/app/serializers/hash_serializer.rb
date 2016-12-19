class HashSerializer
  def self.dump(hash)
    if hash.is_a?(String)
  		hash
  	elsif hash.nil?
      "{}"
    else
  		hash.to_json
  	end
  end

  # Why is this so hard
  # Sometimes it calls this twice, after its already serialized
  # And sometimes a hash comes in that isn't with indifferent access!
  # I don't know where that comes from
  def self.load(hash)
  	result = {}
  	if hash.is_a?(String)
  		result = (JSON.parse(hash||"{}"))
  	else
   		result = hash || {}
   	end
 		result = result.with_indifferent_access if result.is_a?(Hash)
		result
  end
end