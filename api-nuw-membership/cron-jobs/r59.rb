load 'config/application.rb'
Bundler.require


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
		)
		OR (
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
		)
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
	--and memberid = 'NA000067'
WHERE

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

response = JOIN::SubscriptionBatches.post(
	locale: "en",
	join_form_id: "industrial1",
	subscribers: people.map do |p| 
		p.from_api = true
		p.source = 'nuw-api-r59'
		JSON.parse(p.to_json) 
	end
)

unless response.code == 200
	puts response.body
	exit
end

ids = JSON.parse(response.body)['subscriptions'].map { |s| s['id']}

response = JOIN::RecordBatches.post(
	locale: "en", 
	join_form_id: "industrial1", 
	name: "r59_mailout_#{Date.today.iso8601}",
	sms_template_id: 1,
	email_template_id: 1,
	subscription_ids: ids
)

unless response.code == 200
	puts response.body
	exit
end
