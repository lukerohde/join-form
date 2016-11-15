require 'test_helper'

class IncompleteJoinNoticeJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end

  setup do 
    @subscription = subscriptions(:contact_details_only_subscription)
    people(:one).follow!(@subscription.join_form)
    #WickedPdf.new.pdf_from_url(@pdf_url)
    WickedPdf.any_instance.stubs(:pdf_from_url).returns("PDF MOCK")
  end

  test "notice can send" do
    IncompleteJoinNoticeJob.perform_async(@subscription.id, @subscription.updated_at.to_i)
    assert ActionMailer::Base.deliveries.last.subject.starts_with?("JOIN_FOLLOW_UP:"), "was expecting incomplete online join email"
    assert ActionMailer::Base.deliveries.last.to.include?(people(:organiser).email), "was expecting notice to be sent to organiser"
    assert ActionMailer::Base.deliveries.last.cc.include?(people(:one).email), "was expecting notice to be cc'd to follower one"
  end

   test "notice won't send if subscription updated since" do
  	mail_count = ActionMailer::Base.deliveries.count
    IncompleteJoinNoticeJob.perform_in(60*30,@subscription.id, (@subscription.updated_at + 1.minute).to_i)
   	assert mail_count == ActionMailer::Base.deliveries.count, "delayed message shouldn't send if subscription has been updated since it was queued"
   end
end
