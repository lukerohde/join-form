require 'sinatra/base'
require 'sinatra/json'
require 'active_record'
require 'pry-byebug'
require 'ignorable'
require 'bundler'
require 'dotenv'
require 'openssl'
require 'date'

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

		result = p.save!
		if result && payload.dig(:subscription, :pay_method) 
			result = put_pay_method(p, payload)
		end		

		if result
			p.to_json
		else
			status 500
		end
	end

	def put_pay_method(person, payload)
		pm = PayMethod.find_by_MemberID(person.MemberID)
			
		if pm
			pm.assign_attributes(tblBank_attributes(payload))
		else
			pm = PayMethod.new(tblBank_attributes(payload))
			pm.MemberID = person.MemberID
		end
		pm.save!
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
			result[:MemberPaymentType] = api_data[:subscription][:pay_method] == "Credit Card" ? "C" : "D"
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
			Status: "14", # A1p TODO Conditional Potential, Paying
			MemberAwardID: "", 
			MemberFeeGroupID: "GROUPNVA", 
			LastName: "Unknown", 
			MailReturned: 0, 
		}
	end

	def tblBank_attributes(api_data)
		result = {
			DateOfEntry: Date.today.iso8601,
			AccountName: "#{api_data[:first_name]} #{api_data[:last_name]}",
			tblAccountUniqueID: 2, #Nat
			AlternatePayCompanyID: 'NA00449' #Direct Debit National
		}

		subscription = api_data[:subscription] || {}

		case subscription[:pay_method]
			when "Credit Card"
				result = result.merge({
					AccountType: decrypt(subscription[:card_number])[0] == '4' ? 'V' : 'M',
					AccountNo: decrypt(subscription[:card_number]),
					Expiry: "#{subscription[:expiry_month]}/#{(subscription[:expiry_year].to_s)[2..4]}"
				})
			when "Australian Bank Account"
				result = result.merge({
					AccountType: 'S',
					bsb: decrypt(subscription[:bsb]),
					AccountNo: decrypt(subscription[:account_number]),
					FeeOverride: subscription[:establishment_fee] || 0
				})
			end
		result
	end

	def decrypt(value)
		value = Base64.decode64(value)
		@key ||= OpenSSL::PKey::RSA.new(File.read(File.join('config','private.key')))
		@key.private_decrypt(value, OpenSSL::PKey::RSA::PKCS1_PADDING)
	end

	def check_signature(payload)
		
		# build message for signing
		data = payload.reject { |k,v| k == "hmac" }
		data = JSON.parse(data.sort.to_json).to_s
    data = ENV['nuw_end_point_url'] + request.path_info + data
    logger.debug "PROCESSED PAYLOAD: " + data

    # sign message
		hmac_received = payload['hmac'].to_s
		hmac = Base64.encode64("#{OpenSSL::HMAC.digest('sha1',ENV['nuw_end_point_secret'], data)}")
    logger.debug "HMAC: #{hmac}   HMAC_RECEIVED: #{hmac_received}"
    
    # halt if signatures differ
    unless hmac == hmac_received
    	halt 401, "Not Authorized\n"
    end
	end 

	run! if app_file == $0
end 
