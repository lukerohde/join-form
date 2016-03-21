require 'test_helper'

class JoinFormsControllerTest < ActionController::TestCase
  setup do
    @join_form = join_forms(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:join_forms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create join_form" do
    assert_difference('JoinForm.count') do
      post :create, join_form: { attachment: @join_form.attachment, company: @join_form.company, coverage: @join_form.coverage, end_date: @join_form.end_date, local_union_contact: @join_form.local_union_contact, name: @join_form.name, national_union_contact: @join_form.national_union_contact, product_service: @join_form.product_service, start_date: @join_form.start_date, tags: @join_form.tags, union: @join_form.union }
    end

    assert_redirected_to join_form_path(assigns(:join_form))
  end

  test "should show join_form" do
    get :show, id: @join_form
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @join_form
    assert_response :success
  end

  test "should update join_form" do
    patch :update, id: @join_form, join_form: { attachment: @join_form.attachment, company: @join_form.company, coverage: @join_form.coverage, end_date: @join_form.end_date, local_union_contact: @join_form.local_union_contact, name: @join_form.name, national_union_contact: @join_form.national_union_contact, product_service: @join_form.product_service, start_date: @join_form.start_date, tags: @join_form.tags, union: @join_form.union }
    assert_redirected_to join_form_path(assigns(:join_form))
  end

  test "should destroy join_form" do
    assert_difference('JoinForm.count', -1) do
      delete :destroy, id: @join_form
    end

    assert_redirected_to join_forms_path
  end
end
