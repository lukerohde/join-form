# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@record_form_params = -> 
	result = "template_id=" + $('#record_template_id').val() + "&join_form_id=" + $('#record_join_form_id').val() + "&type=" + $('#record_type').val()
	result.replace('null&', '&')