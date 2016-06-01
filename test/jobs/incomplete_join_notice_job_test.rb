require 'test_helper'

class IncompleteJoinNoticeJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end

  setup do 
    @subscription = subscriptions(:contact_details_only_subscription)
    people(:admin).follow!(@subscription.join_form)
  end

  test "notice can send" do
  	IncompleteJoinNoticeJob.perform_async(@subscription.id, @subscription.updated_at.to_i)
    assert ActionMailer::Base.deliveries.last.subject == "luke didn't join - address"
  end

   test "notice won't send if subscription updated since" do
  	mail_count = ActionMailer::Base.deliveries.count
    IncompleteJoinNoticeJob.perform_in(60*30,@subscription.id, (@subscription.updated_at + 1.minute).to_i)
   	assert mail_count == ActionMailer::Base.deliveries.count, "delayed message shouldn't send if subscription has been updated since it was queued"
   end
end
