require 'sinatra/base'
require 'sinatra/json'
require 'active_record'
require 'pry-byebug'
require 'ignorable'
require 'bundler'
require 'dotenv'
require 'openssl'

Bundler.require

Dotenv.load

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlserver",
  :host     => ENV['db_host'],
  :username => ENV['db_username'],
  :password => ENV['db_password'],
  :database => ENV['db_database']
)


class Application < Sinatra::Base

	Dir["./models/*.rb"].each {|file| p file; load file}
	Dir["./config/initializers/*.rb"].each {|file| p file; load file}

	get '/people' do
		check_signature(params)
		p = Person.search(params)
		(p||{}).to_json
	end

	get '/error' do
		1/0
	end

	put '/people' do

		payload = JSON.parse(request.body.read)
		logger.info "Received: #{payload.to_json}"
		check_signature(payload)

		payload.symbolize_keys!
		payload[:subscription].symbolize_keys! if payload[:subscription]
		

		p = Person.search(payload)
		if p
			# update
			p.assign_attributes(tblMember_attributes(payload))
		else
			# insert
			p = Person.new(tblMember_defaults.merge(tblMember_attributes(payload)))
			p.MemberID = member_id
		end

		if p.save!
			logger.info "Sent: #{p.to_json}"
			p.to_json
		else
			status 500
		end
	end

	def member_id 
		ActiveRecord::Base.connection.select_value("GetNewMemberID 'NA'")
	end

	def tblMember_attributes(api_data)

		result = {
				MemberID: api_data[:external_id], 
				FirstName: api_data[:first_name], 
				LastName: api_data[:last_name],
				MemberEmailAddress: api_data[:email],
				MobilePhone: api_data[:mobile],
				Gender: (api_data[:gender]||"")[0],
				MemberResAddress1: api_data[:address1],
				MemberResAddress2: api_data[:address2],
				MemberResSuburb: api_data[:suburb],
				MemberResState: api_data[:state],
				MemberResPostcode: api_data[:postcode]
			}


		if api_data[:subscription]
			result[:MemberPayFrequency] = (api_data[:subscription][:frequency]||"W")[0]
			result[:MemberFeeGroupID] = api_data[:subscription][:plan]
			#TODO Fix fee group	
		end

		result.delete_if { |k,v| v.nil? }

		result
	end

	def tblMember_defaults
		{
			EmpType: "C",
			BranchID: "NA",
			CompanyID: "", # TODO unalloc
			Status: "14", # A1p TODO Conditional Potential
			MemberAwardID: "", 
			MemberFeeGroupID: "GROUPNVA", 
			LastName: "Unknown", 
			MailReturned: 0, 
		}
	end

	def check_signature(payload)
		hmac_received = payload[:hmac].to_s
		payload = payload.reject { |k,v| k == "hmac" }.sort
		hmac = Base64.encode64("#{OpenSSL::HMAC.digest('sha1',ENV['nuw_end_point_secret'], ENV['nuw_end_point_url'] + request.path_info + payload.to_s)}")
    logger.info "HMAC: #{hmac}   HMAC_RECEIVED: #{hmac_received}"
    unless hmac == hmac_received
    	halt 401, "Not Authorized\n"
    end
	end 

	run! if app_file == $0
end 
