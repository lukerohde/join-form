class JoinNoticeJob < ActiveJob::Base
  queue_as :default

  def perform(subscription)
    if subscription.step == :thanks
    	PersonMailer.join_notice(subscription, ENV['mailgun_host']).deliver_now
    end
  end
end
