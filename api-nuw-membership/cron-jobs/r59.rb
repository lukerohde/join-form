load 'config/application.rb'
Bundler.require


puts "\n\nStarting at #{Time.now}"

config = YAML.load_file(File.join('cron-jobs', 'r59.yaml'))

# select Rule59 Members from the past week, and stopped paying members that are one week old and not older than two weeks
puts "Finding people"

if config['test_only'] == true
	people = Application::Person.where('MemberID = ?', config['test_memberid'])
else
	people = Application::Person.where([<<~WHERE, Date.today() - 7, Date.today() - 14, Date.today() - 7])
	(
		( 
			status in (
				select 
					returnvalue1 
				from 
					tblLookup 
				where 
					maincriteria = 'tblMember.status' 
					and returnvalue2 = 'Rule59 Resigned'
			)
			and
				statuschangedate >= ?
				-- TODO prevent people that were selected as stopped, being selected again as R59
		)
		/* OR (
			status in (
				select 
					returnvalue1 
				from 
					tblLookup 
				where 
					maincriteria = 'tblMember.status' 
					and returnvalue2 = 'Stopped Paying'
			)
			and
			statuschangedate >= ?	and statuschangedate < ?	
		) */
	)
	and
		(
			( 
				coalesce(memberemailaddress, '') <> '' 
			)
			or ( 
				coalesce(mobilephone, '') <> ''
			)
		)
	--and 1=0 --memberid = 'NA000067'
	WHERE
end 

# blank out contact details that have bounced or unsubscribed
people.where("memberemailhealth in ('unsubscribed', 'bouncing')").each do |p|
	p.MemberEmailAddress = nil
end

people.where("memberid in (select c.otherid from nuwassist.dbo.contact c inner join nuwassist.dbo.grpcontact gc on c.contactid = gc.contactid where gc.deletiondate is null and gc.grpid in (select lookupid from nuwassist.dbo.lookup where systemvalue = 'smsoptoutgrpid'))").each do |p|
	p.MobilePhone = nil
end		

people.reject! do |p|
	p.MemberEmailAddress.blank? && p.MobilePhone.blank?
end

if people.count == 0 
	puts "Found no one to send too"
	exit
end

puts "Pushing #{people.count} people to join system"
i = 0
ids = []
people.each_slice(10) do |batch|
	i++
	puts "Batch #{i}..."

	# Post subscribers to join system
	response = JOIN::SubscriptionBatches.post(
		locale: config['locale'],
		join_form_id: config['join_form_id'],
		subscribers: batch.map do |p| 
			p.from_api = true
			p.source = 'nuw-api-r59'
			JSON.parse(p.to_json) 
		end
	)

	unless response.code == 200
		puts response.body
		exit
	end

	# Get IDs of subscribers
	ids = ids + JSON.parse(response.body)['subscriptions'].map { |s| s['id']}
end

# Send messages via join system
puts "Sending join form #{config['join_form_id']} to #{ids.count} people"
response = JOIN::RecordBatches.post(
	locale: config['locale'], 
	join_form_id: config['join_form_id'], 
	name: "r59 mailout #{Date.today.iso8601}",
	sms_template_id: config['sms_template_id'],
	email_template_id: config['email_template_id'],
	subscription_ids: ids
)

puts response.body
unless response.code == 201
	exit
end

puts "Completed at #{Time.now}"
exit # otherwise sinatra attempts to start! TODO fix
