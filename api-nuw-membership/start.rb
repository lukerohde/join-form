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


	set :show_exceptions, :after_handler # for json errors in development
	error 500 do
		content_type :json
	  status 500 # internal server error

	  e = env['sinatra.error']
	  
	  request.body.rewind rescue nil
	  body = request.body.read rescue nil
	  url = request.url rescue nil

	  {:result => 'Internal Server Error', :message => e.message, :backtrace => e.backtrace, url: url,  params: params, body: body }.to_json
	end

	get '/people' do
		check_signature(params)
		p = Person.search(params)
		response = (p||{}).to_json
		if (params[:external_id]||"") == "" && !p.nil?
			#fuzzy match
			puts "Fuzzy Matched: #{p.to_json}" rescue nil
		end
		puts "GET Response: #{response}" rescue nil
		response
	end

	put '/people' do

		payload = JSON.parse(request.body.read)
		puts "PUT Received: #{payload.to_json}"
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
		puts "PUT Response: #{response}"
		response
	end

	get '/renew' do 
		p = Person.search(params)
		halt 404, "Not Found\n" unless p
 		
		p.from_api = true
		p.source = "nuw-api-#{params[:source] || "unknown"}"
		payload = JSON.parse(p.to_json)

		result = push_subscribers(payload)
		destination = result['subscriptions'][0]['record_url'] 
		halt result.to_json unless destination

		redirect destination
	end

	post '/renew' do 
		payload = get_subscribers
		result = push_subscribers(payload)

		#halt result.to_json #signed_payload.to_json
		if result['subscriptions'].count == 1
			redirect result['subscriptions'][0]['record_url']
		else
			ids = result['subscriptions'].map{ |s| s['id'] } 
			redirect result['record_batch_url'] + "?subscription_ids=#{ids.join(',')}"
		end
	end

	def get_subscribers
		external_ids = params[:external_ids].split(";")
		source = "nuw-api-#{params[:source] || "unknown"}"

		payload = []
		people = Person.where(MemberID: external_ids)
		people.each do |p|
				p.from_api = true
				p.source = source

		  	payload << JSON.parse(p.to_json)
		end
		halt 404, "Not Found\n" if payload.blank?	
	end

	def push_subscribers(payload)
		response = JOIN::SubscriptionBatches.post(
			locale: params[:locale] || 'en',
			join_form_id: params[:join_form_id],
			subscribers: payload
		)
		JSON.parse(response.body)
  end

  def push_record_batch(ids)
		response = JOIN::RecordBatches.post(
  		locale: params[:locale] || 'en', 
  		name: params[:name],
  		join_form_id: params[:join_form_id],
  		sms_template_id: params[:sms_template_id],
  		email_template_id: params[:email_template_id],
  		subscription_ids: ids
  	)
  	JSON.parse(response.body)
  end

  run! if app_file == $0
end
