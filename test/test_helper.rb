ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/rails/capybara'
require 'minitest/reporters'
require 'mocha/mini_test'
require 'ostruct'

# makes aysnc synchronouse
require 'sucker_punch/testing/inline'

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new(reporter_options)]

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
