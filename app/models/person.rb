class Person < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable,# :registerable,
         :recoverable, :rememberable, :trackable, :validatable



  mount_uploader :attachment, ProfileUploader
  
  belongs_to :union

  #validates :email, presence: true # devise does this already
  validates :union, presence: true
  validate :is_authorized?

  include Filterable
  scope :name_like, -> (name) {where("first_name ilike ? or last_name ilike ? or email ilike ?", "%#{name}%", "%#{name}%", "%#{name}%")}

  def name
  	"#{first_name} #{last_name}"
  end

  def display_name
  	"#{first_name} #{last_name}"
  end

  def authorizer=(person)
    @authorizer = person
  end

  def is_authorized?(person = nil)
    @authorizer = person unless person.blank?
    result = true

    if @authorizer.blank?
      return true if Person.count == 0 # allow first user to be created without authorization
      errors.add(:authorizer, "hasn't be specified, so this person update cannot be made.")
      result = false
    else
      # there is an authorizer
      if @authorizer.union.short_name != ENV['OWNER_UNION']
        # the authorizer isn't an owner
        if self.union_id_was.present? 
          if self.union_id_was != self.union_id
            # there was a union id and it is being changed changed
            errors.add(:union, "cannot be changed.")
            self.union_id = self.union_id_was # put it back
            result = false
          else
            if self.union_id != @authorizer.union_id
              # or the authorizer is attempting to access a person outside their union
              errors.add(:authorizer, "cannot access this person's record.")
              result = false
            end
          end
        else
          if self.union_id != @authorizer.union_id
            # the authorizer is attempting to invite/create a person outside their union
            errors.add(:authorizer, "cannot assign a person to a union other than their own.")
            self.union_id = @authorizer.union_id # put it back
            result = false
          end
        end
      end
    end
    return result
  end

  def reset_password(new_password, new_password_confirmation)
    # patch devise password reset to include authorizer
    self.authorizer = self
    super(new_password, new_password_confirmation)
  end
end
