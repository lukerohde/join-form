module EmailTemplatesHelper

	def new_or_edit_email_template_path(email_template, params)
    email_template && !email_template.try(:new_record?) ? edit_email_template_path(email_template, params) : new_email_template_path(email_template, params)
  end
end
