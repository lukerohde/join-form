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

		if payload.dig(:subscription, :pay_method) 
			set_pay_method(p, payload)
		end

		if payload.dig(:subscription, :payments)
			save_payments(p, payload.dig(:subscription, :payments))
		end

		if p.save!
			p.to_json
		end
	end

	def save_payments(person, payments)
		payments.each do |payment|
			p = person.payments.build(tblTransaction_attributes(person, payment))
			person.PrevFinDate = person.FinDate
			person.FinDate = p.TransactionNewFinDate
		end
	end

	def tblTransaction_attributes(person, payment)
		payment.symbolize_keys!

		findate = person.FinDate || Date.today
		newfindate = get_new_findate(findate, payment[:amount], person.MemberPayFrequency, person.MemberFeeGroupID, person.DateOfBirth)
		result = {
			transactionRefNumber: "nuw_api_#{payment[:id]}",
			TransactionType: person.MemberPaymentType,
			TransactionAmount: payment[:amount],
			TransactionDate: payment[:date], 
			TransactionFinDate: findate, 
			TransactionNewFinDate: newfindate,
			TransactionMadeBy: 'nuw_api',
			TransactionPrevFinDate: person.PrevFinDate,
			TransactionNote: 'Stripe Payment'
		}
		result
	end

	def set_pay_method(person, payload)
		if person.pay_method.present?
			person.pay_method.assign_attributes(tblBank_attributes(payload))
		else
			person.build_pay_method(tblBank_attributes(payload))
		end
	end

	def member_id 
		ActiveRecord::Base.connection.select_value("GetNewMemberID 'NA'")
	end

	def get_new_findate(findate, amount, freq, feegroup, dob)
		dob ||= Date.parse('1950-01-01')
		ActiveRecord::Base.connection.exec_query("select dbo.GetNewFinDate('#{findate.to_date.iso8601}', '#{amount}', '#{freq}', '#{feegroup}', '#{dob.to_date.iso8601}')").rows[0][0]
	end

	def tblMember_attributes(api_data)

		result = {
				MemberID: api_data[:external_id], 
				FirstName: api_data[:first_name], 
				LastName: api_data[:last_name],
				MemberEmailAddress: api_data[:email],
				MobilePhone: api_data[:mobile],
				Gender: (api_data[:gender]||"U"),
				MemberResAddress1: api_data[:address1],
				MemberResAddress2: api_data[:address2],
				MemberResSuburb: api_data[:suburb],
				MemberResState: api_data[:state],
				MemberResPostcode: api_data[:postcode],
				paymentNote: "online join received #{Date.today.strftime('%d-%b-%Y')}"
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
			MemberFeeGroupID: "GroupNoFee", 
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
			when "CC"
				if cn = decrypt(subscription[:card_number])
					result = result.merge({
						AccountType: cn[0] == '4' ? 'V' : 'M',
						AccountNo: cn,
						Expiry: "#{subscription[:expiry_month]}/#{(subscription[:expiry_year].to_s)[2..4]}"
					})
				end
			when "AB"
				if an = decrypt(subscription[:account_number])
					result = result.merge({
						AccountType: 'S',
						bsb: decrypt(subscription[:bsb]),
						AccountNo: an,
						FeeOverride: subscription[:establishment_fee] || 0
					})
				end
			end

		result = result.reject {|k,v| v.nil?}
		result
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
