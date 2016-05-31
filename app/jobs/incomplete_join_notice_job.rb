class IncompleteJoinNoticeJob #< ActiveJob::Base
  #queue_as :default
  include SuckerPunch::Job
	
	def perform(subscription, timestamp_int)
    # this job is delayed x minutes - to allow the user to complete - by which time either 
    # A) the user may have completed, so we shouldn't send an incomplete_notice
		# B) subscription has been changed since notice was sent, so don't send
		#binding.pry if subscription.step == :subscription
    	
		if subscription.step != :thanks && timestamp_int == subscription.updated_at.to_i
    	PersonMailer.incomplete_join_notice(subscription, ENV['mailgun_host']).deliver_now
    end
  end
end
