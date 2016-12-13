require 'test_helper'

class SmsTemplatesControllerTest < ActionDispatch::IntegrationTest
  # include Devise::TestHelpers

  def sign_in_admin
    @admin = people(:admin)
    sign_in @admin
  end

  setup do
    sign_in_admin
    @sms_template = sms_templates(:one)
  end

  test "should get index" do
    get sms_templates_url
    assert_response :success
    assert_not_nil assigns(:sms_templates)
  end

  test "should get new" do
    get new_sms_template_url
    assert_response :success
  end

  test "should create sms_template" do
    assert_difference('SmsTemplate.count') do
      post sms_templates_url(sms_template: { body: @sms_template.body, short_name: @sms_template.short_name })
    end

    assert_redirected_to sms_template_path(assigns(:sms_template))
  end

  test "should show sms_template" do
    get sms_template_url(id: @sms_template)
    assert_redirected_to new_sms_template_preview_path(@sms_template)
  end

  test "should get edit" do
    get edit_sms_template_url(id: @sms_template)
    assert_response :success
  end

  test "should update sms_template" do
    patch sms_template_url(id: @sms_template, sms_template: { body: @sms_template.body, short_name: @sms_template.short_name })
    assert_redirected_to sms_template_path(assigns(:sms_template))
  end

  test "should destroy sms_template" do
    assert_difference('SmsTemplate.count', -1) do
      delete sms_template_url(id: @sms_template)
    end

    assert_redirected_to sms_templates_path
  end
end
