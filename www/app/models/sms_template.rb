class SmsTemplate < ActiveRecord::Base
	validates :short_name, :body, presence: true
	
	include Filterable
  scope :name_like, -> (name) {where("short_name ilike ? or body ilike ?", "%#{name}%", "%#{name}%")}

  def name
  	"#{short_name} - #{body}"
  end
end
