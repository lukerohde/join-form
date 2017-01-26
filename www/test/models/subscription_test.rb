require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
	test "step reported correctly, consequetive times" do
	  s = subscriptions(:completed_subscription)
	  assert s.step == :thanks
	  # was failing the second time because of a problem with person authorization
		assert s.step == :thanks, "second assertion fails"
	end
end
