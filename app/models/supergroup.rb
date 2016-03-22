class Supergroup < ApplicationRecord
	# Used for index searching
  include Filterable
  scope :name_like, -> (name) {where("name ilike ?", "%#{name}%")}
  mount_uploader :logo, LogoUploader

  validates :name, :short_name, presence: true

end
