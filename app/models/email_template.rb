class EmailTemplate < ActiveRecord::Base
	include Bootsy::Container
	validates :short_name, :body_plain, :subject, presence: true
	has_many :join_forms

	include Filterable
  scope :name_like, -> (name) {where("short_name ilike ? or subject ilike ?", "%#{name}%", "%#{name}%")}

  def name
  	"#{short_name} - #{subject}"
  end
end
