module JOIN
	module API
	  def signed_post(end_point, payload)
			signed_payload = SignedRequest::sign(ENV['nuw_end_point_secret'], payload||{}, end_point)
			response = RestClient::Request.execute ({
		  	url: e, 
		  	method: :post, 
		  	payload: signed_payload.to_json,
		  	headers: {
		  		content_type: :json,
		  		accept: :json
	  		},
		  	verify_ssl: false
	  	})
	    result = JSON.parse(response.body)
	  end

		def decrypt(value)
			value = Base64.decode64(value) rescue nil
			if value
				@key ||= OpenSSL::PKey::RSA.new(File.read(File.join('config','private.key')))
				@key.private_decrypt(value, OpenSSL::PKey::RSA::PKCS1_PADDING)
			end
		end

	 	def check_signature(payload)
	 		begin 
	 			SignedRequest::check_signature(ENV['nuw_end_point_secret'], payload, ENV['nuw_end_point_url'] + request.path_info )
	 		rescue SignedRequest::SignatureMismatch
	 			halt 401, "Not Authorized\n"
	 		end
	 	end

	 	def end_point_url(end_point)
	 		YAML.load_file(File.join('config', 'end_points.yaml'))[end_point]
	 	end
	end
end
