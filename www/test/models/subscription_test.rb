require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  test "step reported correctly, consequetive times" do
    s = subscriptions(:completed_subscription)
    assert s.step == :thanks
    # was failing the second time because of a problem with person authorization
    assert s.step == :thanks, "second assertion fails"
  end

  test "save without updating timestamps" do
    params = subscriptions(:completed_subscription).attributes.except("id", "updated_at", "created_at")
    s = Subscription.new(params)
    s.save_without_validation!
    s.reload
    assert !s.new_record?, "record should have saved"
    assert s.updated_at != nil, "new record should have saved with time stamps"
    
    u = s.updated_at
    s.frequency = "Q"
    s.save!
    assert s.updated_at != u, "timestamps should have changed"
    
    u = s.updated_at
    s.frequency = "W"
    s.save_without_validation!
    assert s.updated_at == u, "timestamps shouldn't have changed"
  end
end
