class JoinNoticeJob < ActiveJob::Base
  queue_as :default

  def perform(subscription_id)
  	subscription = Subscription.find(subscription_id)
    if subscription.step == :thanks
    	PersonMailer.join_notice(subscription, ENV['mailgun_host']).deliver_now
    end
  end
end
