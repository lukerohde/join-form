require 'sinatra/base'
require 'sinatra/json'
require 'active_support'
require 'active_support/core_ext'
require 'pry-byebug'
require 'bundler'
require 'openssl'
require 'date'

Bundler.require

class Application < Sinatra::Base

	load 'config/application.rb'

	get '/people' do
		check_signature(params)
		p = Person.search(params)
		response = (p||{}).to_json
		if (params[:external_id]||"") == "" && !p.nil?
			#fuzzy match
			logger.info "Fuzzy Matched: #{p.to_json}" rescue nil
		end
		logger.info "GET Response: #{response}" rescue nil
		response
	end

	put '/people' do

		payload = JSON.parse(request.body.read)
		logger.info "PUT Received: #{payload.to_json}"
		check_signature(payload)

		payload.symbolize_keys!
		payload[:subscription].symbolize_keys! if payload[:subscription]
		

		p = Person.search(payload.slice(:external_id)) # only match a put on external_id, else a fuzzy matched put will by pass verification
		if p
			# update
			p.assign_attributes(tblMember_attributes(payload, p))
		else
			# insert
			p = Person.new(tblMember_defaults.merge(tblMember_attributes(payload)))
			p.MemberID = member_id
		end

		if ["AB", "CC"].include?(payload.dig(:subscription, :pay_method))
			set_pay_method(p, payload)
		end

		if payload.dig(:subscription, :payments).present?
			save_payments(p, payload.dig(:subscription, :payments))
		end

		response = {}
		if p.save!
			response = p.to_json 
		end
		logger.info "PUT Response: #{response}"
		response
	end


	def decrypt(value)
		value = Base64.decode64(value) rescue nil
		if value
			@key ||= OpenSSL::PKey::RSA.new(File.read(File.join('config','private.key')))
			@key.private_decrypt(value, OpenSSL::PKey::RSA::PKCS1_PADDING)
		end
	end

	def check_signature(payload)
		# build message for signing
		data = payload.reject { |k,v| k == "hmac" }

		data = JSON.parse(data.sort.to_json).to_s
    data = data.gsub(/\\u([0-9A-Za-z]{4})/) {|s| [$1.to_i(16)].pack("U")} # repack unicode
    data = ENV['nuw_end_point_url'] + request.path_info + data

    		# sign message
		hmac_received = payload['hmac'].to_s
		hmac = Base64.encode64("#{OpenSSL::HMAC.digest('sha1',ENV['nuw_end_point_secret'], data)}")
    
    # halt if signatures differ
    unless hmac == hmac_received
 	    logger.debug "HMAC MISMATCH!"
 	    logger.debug "HMAC_CALCULATED: #{hmac}   HMAC_RECEIVED: #{hmac_received}"
			logger.debug "PROCESSED PAYLOAD: " + data
      
    	halt 401, "Not Authorized\n"
    end
  end

  run! if app_file == $0
end
