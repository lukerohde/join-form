class JoinNoticeJob < ActiveJob::Base
  queue_as :default

  def perform(subscription_id)
  	ActiveRecord::Base.connection_pool.with_connection do
	    subscription = Subscription.find(subscription_id)
	    if subscription.step == :thanks
	    	subject = "JOIN: Online join from #{ subscription.person.display_name } #{subscription.person.external_id}"
      	emails = subscription.join_form.followers(Person).collect(&:email).join(',')
        unless emails.blank?
        	PersonMailer.subscription_pdf(subscription, emails, subject).deliver_now
	    	end
	    end
	  end
  end
end
