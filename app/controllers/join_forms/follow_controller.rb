class JoinForms::FollowController < ApplicationController
	
  def update
  	@join_form = JoinForm.find(params[:join_form_id])
    current_person.toggle_follow!(@join_form)
    redirect_to request.referrer || edit_union_join_form_path(@union, @join_form)
 	end
end