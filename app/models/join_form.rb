class JoinForm < ApplicationRecord
	belongs_to :union
	belongs_to :person
	has_many :subscriptions, dependent: :delete_all
	
	validates :short_name, :person, :union, presence: true
	validates :base_rate_id, presence: true
	validates :base_rate_weekly, numericality: { allow_blank: true }	
	validate :is_authorized?

	#translates :header, :description

	after_initialize :set_defaults


	def max_frequency
		case
			when self.base_rate_weekly > 0
				"W"
			when self.base_rate_fortnightly > 0
				"F"
			when self.base_rate_monthly > 0
				"M"
			when self.base_rate_quarterly > 0
				"Q"
			when self.base_rate_half_yearly > 0
				"H"
			when self.base_rate_yearly > 0
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
			#membership-card {
				background-color: white; 
				box-shadow: 5px 5px 15px 5px
			}

			#membership-card-top-panel {
			  background-color: red;
			  height: 90px;
			  padding-top: 15px; 
			  padding-left: 15px; 
			  padding-right: 15px
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
