module SmsTemplatesHelper

	def new_or_edit_sms_template_path(sms_template, params)
    sms_template && !sms_template.try(:new_record?) ? edit_sms_template_path(sms_template, params) : new_sms_template_path(sms_template, params)
  end
end
