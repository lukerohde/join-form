ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/rails/capybara'
require 'minitest/reporters'
require 'mocha/mini_test'
require 'ostruct'
require 'capybara/poltergeist'

# makes aysnc synchronouse
require 'sucker_punch/testing/inline'

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new(reporter_options)]

Capybara.register_driver :poltergeist_debug do |app|
  Capybara::Poltergeist::Driver.new(app, :inspector => true)
end

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


# Make JS testing possible with capybara minitest by
# monkey patching DB connection to be shared between test suite and browser,
# disable transactional fixtures and instead wrapping your tests in a
# transaction which gets rolled back
class Capybara::Rails::JSTestCase < Capybara::Rails::TestCase
  include Minitest::Capybara::Behaviour

  def monkey_patch_shared_connection
    @@connection_backup = ActiveRecord::Base.method(:connection)

    ActiveRecord::Base.define_singleton_method(:connection) do
       @@shared_connection ||= ConnectionPool::Wrapper.new(:size => 1) { retrieve_connection }
    end
  end

  def undo_monkey_patch
    ActiveRecord::Base.define_singleton_method(:connection, @@connection_backup)
  end

  def before_setup
    monkey_patch_shared_connection
    self.use_transactional_fixtures = false
    super
    ActiveRecord::Base.connection.begin_transaction #joinable:false, requires_new: true
    Capybara.current_driver = :poltergeist_debug
    Capybara.default_max_wait_time = 10
  end

  def after_teardown
    Capybara.use_default_driver
    ActiveRecord::Base.connection.rollback_transaction
    super
    self.use_transactional_fixtures = true
    undo_monkey_patch
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('jQuery.active').to_i == 0
    end
  end

  def select_wait(option, options = {})
    select option, options
    wait_for_ajax
  end
end
