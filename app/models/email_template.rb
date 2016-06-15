class EmailTemplate < ActiveRecord::Base
	include Bootsy::Container
	validates :short_name, :body_html, :body_plain, :css, :subject, presence: true
end
