class IncompleteJoinNoticeJob #< ActiveJob::Base
  #queue_as :default
  include SuckerPunch::Job
	
	def perform(subscription_id, timestamp_int)
    # this job is delayed x minutes - to allow the user to complete - by which time either 
    # A) the user may have completed, so we shouldn't send an incomplete_notice
		# B) subscription has been changed since notice was sent, so don't send
		#binding.pry if subscription.step == :subscription
    ActiveRecord::Base.connection_pool.with_connection do
      subscription = Subscription.find(subscription_id)
      if subscription.step != :thanks && timestamp_int == subscription.updated_at.to_i
        subject = "JOIN_FOLLOW_UP: Incomplete online join #{ subscription.person.display_name} - stalled on #{subscription.step}"
        emails = subscription.join_form.followers(Person).collect(&:email).join(',')
        unless emails.blank?
          PersonMailer.subscription_pdf(subscription, emails, subject).deliver_now
        end
      end
    end
  end
end
