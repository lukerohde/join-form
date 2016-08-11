require 'base64'
require 'json'
require 'openssl'


module SignedRequest

	class SignatureMismatch < StandardError; end
	class UnsupportedPayload < StandardError; end

	def self.sign(secret_key, payload, url = "")
		data = url + to_comparable_string(payload)
		hmac = get_hmac(secret_key, data)

		if payload.is_a?(Hash)
			payload = payload.merge(hmac: hmac)
		else
			payload = [hmac, payload]
		end
		puts "PROCESSED PAYLOAD: #{data}"
		puts "hmac: #{hmac}"
		payload
	end 

	def self.check_signature(secret_key, payload, url = "")
		if payload.is_a?(String)
			begin 
			  payload = JSON.parse(payload) 
		  rescue
		  	raise SignedRequest::UnsupportedPayload
	  	end
		end 

		if payload.is_a?(Array)
			hmac_received = payload[0]
			payload = payload[1]
		elsif payload.is_a?(Hash) 
			hmac_received = payload['hmac']
			hmac_received ||= payload[:hmac]
			payload = payload.reject { |k,v| k == 'hmac' || k == :hmac }
		else
			raise SignedRequest::UnsupportedPayload
		end

		data = url + to_comparable_string(payload)
		hmac = get_hmac(secret_key, data)

		unless hmac == hmac_received
			puts "HMAC MISMATCH!"
      puts "HMAC_CALCULATED: #{hmac}   HMAC_RECEIVED: #{hmac_received}"
      puts "PROCESSED PAYLOAD: " + data
     
			raise SignedRequest::SignatureMismatch
		end

		payload
	end

	def self.get_hmac(secret_key, data)
		Base64.encode64("#{OpenSSL::HMAC.digest('sha1',secret_key, data)}")
	end

	private

	def self.to_comparable_string(data)
		
		unless data.is_a?(String)
			# convert to json and back to fix date formats and stringify keys
			data = JSON.parse(data.to_json)

			# sort to make param order is consistent (params need to be sorted but json payloads probably don't)
			data = deep_sort(data).to_json
		end

		# repack unicode, which is some weird circumstance gets unpacked like \u9a1C, (case can be a mixed!)
		data.gsub(/\\u([0-9A-Za-z]{4})/) {|s| [$1.to_i(16)].pack("U")} 
	end

  # Recursively deep sort (it won't handle an array containing a hash value, i.e. values of differing types that can't be compared)
	def self.deep_sort(data)
		if data.is_a?(Array)
			data.each_with_index do |v, index|
				data[index] = deep_sort(v)
			end
			data = data.sort rescue data # hope for the best
		elsif data.is_a?(Hash)
			data.each do |k,v|
				data[k] = deep_sort(v)
			end
			data = data.sort.to_h rescue data # hope for the best
		end

		data
	end
end

