require 'test_helper'

class EmailTemplatesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def sign_in_admin
    @admin = people(:admin)
    sign_in @admin
  end

  def setup
    sign_in_admin
    @email_template = email_templates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:email_templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create email_template" do
    assert_difference('EmailTemplate.count') do
      post :create, email_template: { attachment: @email_template.attachment, body_html: @email_template.body_html, body_plain: @email_template.body_plain, css: @email_template.css, subject: @email_template.subject, short_name: @email_template.short_name }
    end

    assert_redirected_to email_template_path(assigns(:email_template))
  end

  test "should show email_template" do
    get :show, id: @email_template
    assert_response :redirect
    assert response.redirect_url ==  new_email_template_preview_url(@email_template), "didn't redirect to preview"
  end

  test "should get edit" do
    get :edit, id: @email_template
    assert_response :success
  end

  test "should update email_template" do
    patch :update, id: @email_template, email_template: { attachment: @email_template.attachment, body_html: @email_template.body_html, body_plain: @email_template.body_plain, css: @email_template.css, subject: @email_template.subject, short_name: @email_template.short_name }
    assert_redirected_to email_template_path(assigns(:email_template))
  end

  test "should destroy email_template" do
    assert_difference('EmailTemplate.count', -1) do
      delete :destroy, id: @email_template
    end

    assert_redirected_to email_templates_path
  end
end
