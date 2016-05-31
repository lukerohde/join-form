require 'test_helper'

class IncompleteJoinNoticeJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "notice can send" do
  	subscription = subscriptions(:contact_details_only_subscription)
    IncompleteJoinNoticeJob.perform_async(subscription.id, Time.now.to_i)
    assert ActionMailer::Base.deliveries.last.subject == "luke didn't join - address"
  end

   test "notice won't send if subscription updated since" do
  	subscription = subscriptions(:contact_details_only_subscription)
    mail_count = ActionMailer::Base.deliveries.count
    IncompleteJoinNoticeJob.perform_in(60*30,subscription.id, (subscription.updated_at + 1.minute).to_i)
   	assert mail_count == ActionMailer::Base.deliveries.count, "delayed message shouldn't send if subscription has been updated since it was queued"
   end

   test "notice should send if subscription just updated" do
  	subscription = subscriptions(:contact_details_only_subscription)
    mail_count = ActionMailer::Base.deliveries.count
    IncompleteJoinNoticeJob.perform_in(60*30,subscription.id, subscription.updated_at.to_i)
   	assert ActionMailer::Base.deliveries.count - mail_count == 1, "delayed message shouldn't send if subscription has been updated since it was queued"
   end
end
