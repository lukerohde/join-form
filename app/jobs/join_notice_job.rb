class JoinNoticeJob < ActiveJob::Base
  queue_as :default

  def perform(subscription_id)
  	subscription = Subscription.find(subscription_id)
    if subscription.step == :thanks
    	subscription.join_form.followers(Person).each do |person|
      	PersonMailer.join_notice(subscription, ENV['mailgun_host'], person.email).deliver_now
   		end
    end
  end
end
