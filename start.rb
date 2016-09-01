require 'sinatra/base'
require 'sinatra/json'
require 'active_support'
require 'active_support/core_ext'
require 'pry-byebug'
require 'bundler'
require 'openssl'
require 'date'
require 'rest-client'
require './lib/signed_request.rb'

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

	get '/renew' do 
		p = Person.search(params)
		p.from_api = true

		join_form_id = params[:join_form_id]
		locale = params[:locale] || 'en'
    
    end_points = YAML.load_file(File.join('config', 'end_points.yaml'))
		
		results = []
		end_points.each do |e|
			e = e.gsub('join_form_id', join_form_id)
			e = e.gsub('locale', locale)
			puts e
			payload = JSON.parse(p.to_json)
			puts payload
			signed_payload = SignedRequest::sign(ENV['nuw_end_point_secret'], payload||{}, e)
		  response = RestClient::Request.execute ({
		  	url: e, 
		  	method: :post, 
		  	#payload: { first_name: 'luke', last_name: 'rohde', email: 'lrohde@nuw.org.au', external_id: 'NV391215'}.to_json, 
		  	payload: signed_payload.to_json,
		  	#payload: payload.to_json,
		  	headers: {
		  		content_type: :json,
		  		accept: :json
	  		},
		  	verify_ssl: false
	  	})
      result = JSON.parse(response.body)
      results << result
		end
		redirect results[0]['url']
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

  run! if app_file == $0
end
