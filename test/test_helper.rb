ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def sign_in(person)
		# device testhelpers don't work in Rails 5 yet!
	  post person_session_path \
	    "person[email]"    => person.email,
	    "person[password]" => "password"
	end

end
