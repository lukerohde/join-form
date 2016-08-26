class SMS < Record
	def template
		@template ||= SmsTemplate.find_by_id(self.template_id)
	end

	def merge(data)
		if template
	 		self.body_plain = Liquid::Template.parse(template.body).render(data) 
 		end 
	end
end