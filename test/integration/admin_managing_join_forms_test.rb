require 'test_helper'

class AdminManagingJoinFormsTest < ActionDispatch::IntegrationTest

	setup do 
		@current_person = people(:admin)
		@owner = supergroups(:owner)
		sign_in @current_person
	end

	test "admin can get list of join forms" do
		get "/join_forms"
		assert_response :success
  end

  test "admin can create a join form" do
  	get "/join_forms/new"
  	assert_response :success

  	assert_difference("JoinForm.count") do
  		post "/join_forms", params: { join_form: { short_name: "test", union_id: @owner.id, person_id: @current_person.id }}
  	end
  	assert_redirected_to union_path(@owner)
  	assert "Your new join form was successfully created." == flash[:notice], "Notice not set correctly"
  end

  test "admin can destroy join form" do

  end

  test "admin can update join form" do

  end

end
