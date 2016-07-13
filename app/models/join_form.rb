class JoinForm < ApplicationRecord
	belongs_to :union
	belongs_to :person
	belongs_to :welcome_email_template, class_name: "EmailTemplate"
	belongs_to :admin_email_template, class_name: "EmailTemplate"
	
	has_many :subscriptions, dependent: :delete_all
	
	acts_as_followable
	
	after_initialize :set_defaults

	include Bootsy::Container

	translates :description, :page_title, :schema, :header, :footer, :css, :wysiwyg_header, :wysiwyg_footer
	#translation_class.send :serialize, :schema
	#serialize :schema, JSONSerializer
	
	validates :short_name, :person, :union, presence: true
	validates :base_rate_id, presence: true
	validates :base_rate_weekly, numericality: { allow_blank: true }	
	validate :is_authorized?
	validate :has_pay_method
	validate :signature_for_prd_and_abr
	validate :no_establishment_fee_for_prd_and_abr

	def signature_for_prd_and_abr
		if (payroll_deduction_on || direct_debit_release_on) && !signature_required
			errors.add :base, "Signature must be turned on for forms with direct debit release or payroll deduction"
		end
	end

	def no_establishment_fee_for_prd_and_abr

		if (payroll_deduction_on) && base_rate_establishment > 0
			errors.add :base, "You cannot charge an up front payment when payroll deduction is enabled"
		end

	end

	def has_pay_method
		unless self.credit_card_on || self.direct_debit_on || self.payroll_deduction_on || self.direct_debit_release_on
			errors.add(:base, "You need at lease one pay method enabled")
		end
	end

	def max_frequency
		case
			when self.base_rate_weekly||0 > 0
				"W"
			when self.base_rate_fortnightly||0 > 0
				"F"
			when self.base_rate_monthly||0 > 0
				"M"
			when self.base_rate_quarterly||0 > 0
				"Q"
			when self.base_rate_half_yearly||0 > 0
				"H"
			when self.base_rate_yearly||0 > 0
				"Y"
			end	
	end

	def fee(frequency)
		case frequency
      when  "W" 
        self.base_rate_weekly || 0
      when  "F" 
        self.base_rate_fortnightly || 0
      when  "M" 
        self.base_rate_monthly || 0
      when  "Q" 
        self.base_rate_quarterly || 0
      when  "H" 
        self.base_rate_half_yearly || 0
      when  "Y" 
        self.base_rate_yearly || 0
      end
	end

	def pay_methods
		result = []
		result << "AB" if direct_debit_on
		result << "CC" if credit_card_on
		result << "ABR" if direct_debit_release_on
		result << "PRD" if payroll_deduction_on
		result
	end
	
	def set_defaults

		self.css ||= <<-CSS.gsub(/^\t{3}/,'')
			/* background colour */
			body {
			 background-color: #fee;
			}

			/* heading colors */
			h1,h2,h
			  color: #D33;
			}

			/* label colours */
			.form-group > label {
			  color:#555555;
			}

			/* control colours */
			.form-control {
			  background-color: #fff;
			  color: #555555;
			}

			/* descriptive detail for emphasis */
			.detail {
				color: #D33;
			}

						
			/* membership card styling */
			.membership-card {
				background-color: white; 
				width: 300px;
				height: 170px;
				border-radius: 10px;
				margin-left: auto;
				margin-right: auto;
			}

			#membership-card-top-panel {
			  background-color: red;
			  height: 90px;
			  padding-top: 15px; 
			  padding-left: 15px; 
			  padding-right: 10px;
			  border-radius: 10px 10px 0px 0px;
			}

			#membership-card-union-name {
			  width: 70%; 
			  float:left; 
			  text-align: left;
			  font-weight: bold;
			  font-style: italic;
			  font-size: 1.4em;
			  color: white;
			}

			#membership-card-union-logo {
			  width: 20%; 
			  float:right;
			}

			#membership-card-union-logo > img {
			  width: 100%
			}

			#membership-card-bottom-panel {
			  background-color: white;
			  height: 102px;
			  padding-right:15px; 
			  padding-left:15px;
			  padding-top:15px;
			  border-radius: 0px 0px 10px 10px;
			}

			#membership-card-person-name {
			  float:left;
			  font-weight: bold;
			}

			#membership-card-person-id {
			   float:right;
			   font-weight: bold;
			}

			#membership-card-status {
			  float: left;
			  font-size: 1rem;
			}

		CSS

	end

	# My plan is to have an advanced schema designer, but for now I've got a simple list of columns
	# Can't use custom jsonb or custom serializer with globalize - boo
	def column_list=(cols)
			self.schema	 = schema_data.merge({ 
				columns: (cols||"").split(',').map{|i| i.strip }
			}).to_json
	end

	def column_list
			(schema_data[:columns]||[]).join(', ')
	end

	def schema_data
		JSON.parse(self.schema||"{}").with_indifferent_access
	end

	#def schema
	#	# globalize stores it as a string any way, I want it back as a hash
	#	JSON.parse(self.schema||"{}").with_indifferent_access
	#end

	def authorizer=(person)
		@authorizer = person
	end

	def is_authorized?(person = nil)
		@authorizer = person unless person.blank?
		
		if @authorizer.blank?
			errors.add(:authorizer, "hasn't be specified, so this update cannot be made.")
			return
		end

		if @authorizer.union.short_name != ENV['OWNER_UNION']
			if self.union_id != @authorizer.union_id
				errors.add(:union, "is not your union so this assignment is not authorized.")
			end 

			if self.person.present? && self.person.union_id != @authorizer.union_id
				errors.add(:person, "is not a colleague from your union so this assignment is not authorized.")
			end
		end
	end
end
