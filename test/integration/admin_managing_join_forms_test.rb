require 'test_helper'

class AdminManagingJoinFormsTest < ActionDispatch::IntegrationTest

	setup do 
		@current_person = people(:admin)
		@owner = supergroups(:owner)
		sign_in @current_person
	end

	test "admin can get list of join forms" do
		get "/join_forms"
		assert_redirected_to union_url(@current_person.union)
  end

  test "admin can create a join form" do
  	get "/join_forms/new"
  	assert_response :success

  	assert_difference("JoinForm.count") do
  		post "/join_forms", join_form: { short_name: "test", union_id: @owner.id, admin_id: @current_person.id, organiser_id: @current_person.id, base_rate_id: "GROUPNVA", credit_card_on: true }
  	end
  	assert_redirected_to union_path(@owner)
  	assert "Your new join form was successfully created." == flash[:notice], "Notice not set correctly"
  end

  test "admin can destroy join form" do
  	id = join_forms(:one).id
  	get edit_join_form_path(id)
  	assert_response :success
  	assert_select "a[href=?]", join_form_path(id), { count: 1, text: "Permanently Delete This Join Form"}, "Join form delete link is missing"

  	delete join_form_path(id)
  	assert_redirected_to union_path(@owner)
  	assert 'The join form was successfully destroyed.' == flash[:notice], "Destroy flash was wrong"
  end 

  test "admin can update join form" do
  	one = join_forms(:one)
		get edit_join_form_path(one)
  	assert_response :success

  	patch join_form_path(one.id), join_form: { short_name: "new name", admin_id: @current_person.id, base_rate_id: "GROUPNVA"} 
  	assert_redirected_to edit_union_join_form_path(one.union, one)
		assert 'The join form was successfully updated.' == flash[:notice], "Update flash was wrong"
		one.reload
		assert_equal "new name", one.short_name
  end

  test "admin can't see join form read only" do
	  j = join_forms(:one)
    u = j.union
  	get join_form_path(join_forms(:one))
    assert_redirected_to "http://www.example.com/en/#{u.short_name}/#{j.short_name}/join"
  end

  test "admin can add custom columns" do
    one = join_forms(:one)
    get edit_join_form_path(one)
    assert_response :success
    
    assert response.body.include?('name="join_form[column_list]"'), "column list field is missing"  
    patch join_form_path(one.id), join_form: { short_name: "new name", admin_id: @current_person.id, column_list: "a,b"} 
    one.reload
    assert one.column_list == "a, b", "custom columns cannot be set"
  end

end
