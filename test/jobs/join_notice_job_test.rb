require 'test_helper'

class JoinNoticeJobTest < ActiveJob::TestCase
  test "join notice only sends when joined" do
  	subscription = subscriptions(:contact_details_with_subscription_and_pay_method_subscription)
    JoinNoticeJob.perform_now(subscription)
    assert ActionMailer::Base.deliveries.last.subject == "luke joined - thanks"
  end

	test "join notice doesn't send when join is incomplete" do
  	subscription = subscriptions(:contact_details_only_subscription)
    mail_count = ActionMailer::Base.deliveries.count
    JoinNoticeJob.perform_now(subscription)
    assert ActionMailer::Base.deliveries.count == mail_count # shouldn't increase
  end
 
  test "join notice is sent on post" do
  	# this is tested in subscription_controller_public_test to avoid code duplication
  end

end
