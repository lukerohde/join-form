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
		response = (p||{}).to_json
		if (params[:external_id]||"") == "" && !p.nil?
			#fuzzy match
			logger.info "Fuzzy Matched: #{p.to_json}"
		end
		logger.info "GET Response: #{response}"
		response
	end

	get '/error' do
		1/0
	end

	put '/people' do

		payload = JSON.parse(request.body.read)
		logger.info "PUT Received: #{payload.to_json}"
		check_signature(payload)

		payload.symbolize_keys!
		payload[:subscription].symbolize_keys! if payload[:subscription]
		

		p = Person.search(payload)
		if p
			# update
			p.assign_attributes(tblMember_attributes(payload, p))
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

		response = {}
		if p.save!
			response = p.to_json 
		end
		logger.info "PUT Response: #{response}"
		response
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

	def tblMember_attributes(api_data, person = nil)

		note = "" 
		note += "Online join on #{Date.today.strftime('%d-%b-%Y')}.  "
		note += "Initial charge: #{api_data[:subscription][:establishment_fee]}.  " if (api_data.dig(:subscription, :establishment_fee)||"0").to_f > 0
		if api_data.dig(:subscription, :data)
			note += api_data[:subscription][:data].map { |k,v| "#{k}: #{v}" }.join(", ") + ".  "
		end
		note += "url: #{api_data[:subscription][:url]}  " if api_data.dig(:subscription,:url)
		# note += person.paymentNote if person.paymentNote, figure out how not to erase existing payment note, but also not concat redundant notes

		dob = Time.parse(api_data[:dob]) rescue nil # use Time instead of Date since sql returns datetime ( needed for correct comparison and change logging )

		result = {
				MemberID: api_data[:external_id], 
				FirstName: api_data[:first_name], 
				LastName: api_data[:last_name],
				MemberEmailAddress: api_data[:email],
				MobilePhone: (api_data[:mobile]||"").gsub('+61', '0').gsub(/[^\d]/,'')[0..9],
				Gender: (api_data[:gender]||"U"),
				DateOfBirth: dob, 
				MemberResAddress1: api_data[:address1],
				MemberResAddress2: api_data[:address2],
				MemberResSuburb: api_data[:suburb],
				MemberResState: api_data[:state],
				MemberResPostcode: (api_data[:postcode]||"")[0..3],
				paymentNote: (note||"")[0..3999] # varchar max
			}

		if api_data[:subscription]
			
			current_status = person.Status if person
			status = "17" unless current_status # potential member
			status = "14" if (current_status.nil? || current_status == "17") && api_data[:subscription][:pay_method]
			#status = "14" if (current_status == "1") && api_data[:subscription][:pay_method] # TODO I don't want to update a person's status when we ahven't tested their card, but I do want to provide feedback that we are expecting payment, Maybe fake a status by looking at the retrypaymentdate
			status = "1" if api_data[:subscription][:payments] && api_data[:subscription][:payments].length > 0
			result[:Status] = status if status
			result[:StatusChangeDate] = Date.today if status

			result[:MemberPayFrequency] = (api_data[:subscription][:frequency]||"W")[0]
			result[:MemberFeeGroupID] = api_data[:subscription][:plan]
			result[:MemberPaymentType] = api_data[:subscription][:pay_method] == "Credit Card" ? "C" : "D"
			
			if ((person && !["1", "14"].include?(person.Status)) || person.nil?) && api_data[:subscription][:pay_method]
				# if the person is new or the person isn't status 1 or 14, then set the findate and nextpaymentdate
				result[:nextpaymentdate] = Date.today # TODO We should be updating this or findate if the person already has one set and isn't resetting it.  
				result[:FinDate] = Date.today - 1
			end
		end

		result.delete_if { |k,v| v.nil? }

		result
	end

	def tblMember_defaults
		{
			EmpType: "C",
			BranchID: "NA",
			CompanyID: "NA00001", 
			MemberPayCompanyID: "NA00001",
			CompanyStartDate: Date.today, 
			FinDate: Date.today-1,
			JoinDate: Date.today, 
			MemberAwardID: "", 
			MemberFeeGroupID: "GroupNoFee", 
			LastName: "Unknown", 
			MailReturned: 0
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
					m = "0#{subscription[:expiry_month].to_s}"[-2..-1] # pad with proceeding zero
					y = (subscription[:expiry_year].to_s)[2..4]
					result = result.merge({
						AccountType: cn[0] == '4' ? 'V' : 'M',
						AccountNo: cn,
						Expiry: "#{m}/#{y}",
						RetryPaymentDate: Date.today, 
						RetryPaymentUser: 'nuw-api'
					})
				end
			when "AB"
				if an = decrypt(subscription[:account_number])
					b = decrypt(subscription[:bsb]).to_s
					result = result.merge({
						AccountType: 'S',
						bsb: "#{b[0..2]}-#{b[-3..-1]}",
						AccountNo: an,
						FeeOverride: (subscription[:establishment_fee] || "0").to_f,
						RetryPaymentDate: Date.today, 
						RetryPaymentUser: 'nuw-api'
					})
				end
			when "-"
				f = (subscription[:establishment_fee] || "0").to_f
				if f >= 0.01
					result = {
						FeeOverride: f
					}
				else
					result = {}
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
