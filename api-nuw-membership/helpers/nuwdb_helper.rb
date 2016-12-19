
module NUWDBHelper


	def save_payments(person, payments)
		person.FinDate ||= (Date.today - 1.day) # shouldn't be needed, but just in case
		payments.each do |payment|
			p = person.payments.build(tblTransaction_attributes(person, payment))
			person.PrevFinDate = person.FinDate
			person.FinDate = p.TransactionNewFinDate
		end
		person.nextpaymentdate = get_next_payment_date_after(person.FinDate, person.nextpaymentdate || person.FinDate, person.MemberPayFrequency)
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
		data = tblBank_attributes(payload)
		if person.pay_method.present?
			person.pay_method.assign_attributes(data)
		else
			person.build_pay_method(data)
		end
	end

	def member_id 
		ActiveRecord::Base.connection.select_value("GetNewMemberID 'NA'")
	end

	def get_new_findate(findate, amount, freq, feegroup, dob)
		dob ||= Date.parse('1950-01-01')
		ActiveRecord::Base.connection.exec_query("select dbo.GetNewFinDate('#{findate.to_date.iso8601}', '#{amount}', '#{freq}', '#{feegroup}', '#{dob.to_date.iso8601}')").rows[0][0]
	end

	def get_current_pay_period_length(dte, freq, direction)
		ActiveRecord::Base.connection.exec_query("select dbo.GetCurrentPayPeriodLength('#{dte.to_date.iso8601}', '#{freq}', '#{direction}')").rows[0][0]
	end

	def get_next_payment_date(dte, freq)
		ActiveRecord::Base.connection.exec_query("select dbo.GetNextPaymentDate('#{dte.to_date.iso8601}', '#{freq}')").rows[0][0]
	end

	def get_next_payment_date_after(after, dte, freq)
		ActiveRecord::Base.connection.exec_query("select dbo.GetNextPaymentDateAfter('#{after.to_date.iso8601}', '#{dte.to_date.iso8601}', '#{freq}')").rows[0][0]
	end

	def get_first_recurrent_payment_date(next_payment_date, findate, establishment_fee, freq, feegroup, dob)
		new_findate = get_new_findate(findate, establishment_fee, freq, feegroup, dob)
		get_next_payment_date_after(new_findate, next_payment_date||Date.today, freq)
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
		gender = api_data[:gender] || "U" 
		gender = "" if gender == "U" && person.present? # don't set to unknown if person is existing

		result = {
				MemberID: api_data[:external_id], 
				FirstName: api_data[:first_name], 
				PreferredName: api_data[:preferred_name] || api_data[:first_name], 
				LastName: api_data[:last_name],
				MemberEmailAddress: api_data[:email],
				MobilePhone: (api_data[:mobile]||"").gsub('+61', '0').gsub(/[^\d]/,'')[0..9],
				Gender: gender,
				DateOfBirth: dob, 
				MemberResAddress1: (api_data[:address1]||"")[0..69],
				MemberResAddress2: (api_data[:address2]||"")[0..34],
				MemberResSuburb: (api_data[:suburb]||"")[0..24],
				MemberResState: (api_data[:state]||"")[0..49],
				MemberResPostcode: (api_data[:postcode]||"")[0..3],
				MemberPostAddress1: (api_data[:address1]||"")[0..69],
				MemberPostAddress2: (api_data[:address2]||"")[0..34],
				MemberPostSuburb: (api_data[:suburb]||"")[0..24],
				MemberPostState: (api_data[:state]||"")[0..49],
				MemberPostPostcode: (api_data[:postcode]||"")[0..3],
				paymentNote: (note||"")[0..3999] # varchar max
			}

		if api_data[:subscription]
			
			current_status = person.Status if person
			status = "17" unless current_status # potential member
			status = "14" if (current_status.nil? || current_status == "17") && api_data[:subscription][:pay_method]
			#status = "14" if (current_status == "1") && api_data[:subscription][:pay_method] # TODO I don't want to update a person's status when we ahven't tested their card, but I do want to provide feedback that we are expecting payment, Maybe fake a status by looking at the retrypaymentdate
			status = "1" if api_data[:subscription][:payments] && api_data[:subscription][:payments].length > 0
			result[:Status] = status if status
			result[:StatusChangeDate] = Date.today if status && status != current_status

			result[:MemberPayFrequency] = (api_data[:subscription][:frequency]||"W")[0]
			result[:MemberFeeGroupID] = api_data[:subscription][:plan]
			result[:CompanyID] = api_data[:subscription][:group_id] if api_data[:subscription][:group_id].present?
			result[:MemberPayCompanyID] = api_data[:subscription][:group_id] if api_data[:subscription][:group_id].present?

			if api_data[:subscription][:tags].present?
				tags = person.MemberTags if person
				tags ||= ""
				tags = tags.split(',') + (api_data[:subscription][:tags]||"").split(',')
				tags = tags.uniq.join(",")
				result[:MemberTags] = tags
			end

			case api_data[:subscription][:pay_method]
				when "CC" then result[:MemberPaymentType] = "C"
				when "AB" then result[:MemberPaymentType] = "D"
				when "ABR" then result[:MemberPaymentType] = "R"
				when "PRD" then result[:MemberPaymentType] = "O"
			end

			if result[:MemberPaymentType]
				# If a new payment method has been provided, also set next payment date
				result[:nextpaymentdate] = api_data[:subscription][:next_payment_date] || Date.today 
				if person.nil? || person.FinDate.nil? || person.FinDate < Date.today
					# reset the findate, if behind or not set.  This also lets people have advanced financial dates
					result[:FinDate] = Date.today - 1.day # either one or two days behind next_payment_date, so one payment will be charged to get ahead
				else
					# make sure next payment date is in advance of findate, else the nothing will be charged on the next payment date
					result[:nextpaymentdate] = get_next_payment_date_after(person.FinDate, result[:nextpaymentdate], result[:MemberPayFrequency])
				end
				result[:nextpaymentdate] += 1.day if result[:nextpaymentdate] == Date.today && Time.now > (Date.today + 12.hours) # batches are generated at 12pm, set to tomorrow if deadline has been missed
			end 
		end

		# delete keys if they are blank, unless they are address fields
		result.delete_if { |k,v| v.blank? && !k.to_s.starts_with?('MemberRes') && !k.to_s.starts_with?('MemberPost')}

		result
	end

	def tblMember_defaults
		{
			EmpType: "C",
			BranchID: "NA",
			CompanyID: "NA00001", 
			MemberPayCompanyID: "NA00001",
			CompanyStartDate: Date.today, 
			FinDate: Date.today - 1.day,
			JoinDate: Date.today, 
			MemberAwardID: "", 
			MemberFeeGroupID: "GroupNoFee", 
			MemberPaymentType: "D", 
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
						AccountNo: cn.gsub(/[^0-9]/,""),
						Expiry: "#{m}/#{y}",
						RetryPaymentDate: Date.today, 
						RetryPaymentUser: 'nuw-api', 
						InvalidationDate: nil, 
						InvalidationUser: nil
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
						RetryPaymentUser: 'nuw-api', 
						InvalidationDate: nil, 
						InvalidationUser: nil
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

		#result = result.reject {|k,v| v.nil?} # removed this because system couldn't remove invalidation
		result
	end
end
