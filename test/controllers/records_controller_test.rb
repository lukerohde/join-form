require 'test_helper'

class RecordsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def sign_in_admin
    @admin = people(:admin)
    sign_in @admin
  end

  setup do
    sign_in_admin
    @record = records(:one)
    @subscription = subscriptions(:one)
  end

  test "should get new" do
    get :new, subscription_id: @subscription.id
    assert_response :success
  end

  test "should create record" do
    assert_difference('Record.count') do
      post :create, subscription_id: @subscription.id, record: { body_plain: @record.body_plain, subject: @record.subject, template_id: @record.template_id, type: 'SMS' }
    end
    assert_redirected_to new_subscription_record_path(@subscription)
  end

  test "should show record" do
    get :show, subscription_id: @subscription.id, id: @record
    assert_response :success
  end

  test "should destroy record" do
    assert_difference('Record.count', -1) do
      delete :destroy, subscription_id: @subscription.id, id: @record
    end

    assert_redirected_to new_subscription_record_url(@subscription)
  end
end
