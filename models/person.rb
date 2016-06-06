class Application
	class Person < ActiveRecord::Base
		self.table_name = "tblMember"
		self.primary_key = "MemberID"

		ignore_columns :tblMemberUniqueID

		has_many :payments, foreign_key: "MemberID", autosave: true
		has_many :notes, foreign_key: "MemberID", autosave: true
		has_one :pay_method, foreign_key: "MemberID", autosave: true

		delegate :FeeOverride, to: :pay_method, allow_nil: true
		delegate :RetryPaymentDate, to: :pay_method, allow_nil: true

		def self.search(api_data)
			result = self.find_by_MemberID(api_data[:external_id]) if api_data[:external_id].to_s != ""
			# find by email (except deceased) - husbands and wives share email, but there are more typos and alt spellings, better off just picking the most recent
			if result.nil? && api_data[:email].to_s != ""
				result = self.where(["Status <> '6' and MemberEmailAddress = ? OR MemberSecondaryEmailAddress = ?", api_data[:email], api_data[:email]]) 
				result = result.order("findate DESC")
				result = result.first
			end

			# find by mobile (except deceased) - mobile phones change hands, but there are more typos and alt spellings, better off just picking the most recent
			if result.nil? && api_data[:mobile].to_s != ""
				result = self.where(["Status <> '6' and replace(replace(replace(replace(mobilephone,' ', ''), '(', ''), ')', ''), '-', '') = ?", api_data[:mobile].gsub(/[^0-9]/,'')]) 
				result = result.order("FinDate DESC")
				result = result.first
			end

			result
		end

		def friendly_status
				result = ActiveRecord::Base.connection.exec_query("select returnvalue2 from tblLookup where returnvalue1 = '#{self.Status}' and maincriteria = 'tblMember.status'").rows[0][0]
				unless ["awaiting 1st payment", "paying"].include?(result.downcase) 
						result = 'Pending' if self.RetryPaymentDate
				end
				result
		end

		def to_json
			result = {
				external_id: self.MemberID
			}

			transactions = self.payments.where(['TransactionDate > ?', (Date.today - 365).iso8601]).collect do |p| # todo change to at least one whole financial year
				{
					id: p.transactionRefNumber,
					date: p.TransactionDate,
					amount: p.TransactionAmount,
					external_id: p.tblTransactionUniqueID
				}
			end

			# Fake a payment for the sake of showing it as done
			# Brilliant or Nasty - not sure - should be faking an invoice, or having an unpaid status
			if self.FeeOverride
				transactions << {
					id: "ORDER#{pay_method.DateOfEntry.to_i}",
					date: pay_method.DateOfEntry,
					amount: pay_method.FeeOverride,
					external_id: "ORDER#{pay_method.DateOfEntry.to_i}"
				}
			end
			
			# only reveal information for people who've paid us, or have a current payment problem - people with bad statii who never paid us have never given us authoriative info, worth keeping at least.  
			# Specifically exclude potential members, non-union, or ex-potential members - they may not expect us having information on them
			if (transactions.count > 0 || ['14','23','24','25'].include?(self.Status)) && !['17', '19', '26'].include?(self.Status)
				result = result.merge({
					external_id: self.MemberID,
					first_name: self.FirstName,
					last_name: self.LastName,
					email: self.MemberEmailAddress,
					mobile: self.MobilePhone,
					gender: self.Gender,
					dob: self.DateOfBirth,
					address1: self.MemberResAddress1,
					address2: self.MemberResAddress2,
					suburb: self.MemberResSuburb,
					state: self.MemberResState,
					postcode: self.MemberResPostcode,
					subscription: {
						status: self.friendly_status,
						frequency: self.MemberPayFrequency,
						plan: self.MemberFeeGroupID == "GroupNoFee" ? "" : self.MemberFeeGroupID,
						pay_method: '-', #case when self.MemberPaymentType == 'C' then 'CC' else 'AB' end, 
						payments: transactions,
					}, 
				})
			end

			result.to_json
		end



	end
end