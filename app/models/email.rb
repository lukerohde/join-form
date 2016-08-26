class Email < Record
	def template
		@template ||= EmailTemplate.find_by_id(self.template_id)
	end

	def merge(data)
		if self.template
	 		self.subject = Liquid::Template.parse(template.subject).render(data)
    	self.body_plain = Liquid::Template.parse(template.body_plain).render(data)  
		end
	end
end