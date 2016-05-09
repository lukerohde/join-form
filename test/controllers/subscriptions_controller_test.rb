require 'test_helper'
include ApplicationHelper

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @join_form = join_forms(:one)
    @union = @join_form.union
    @new_subscription = Subscription.new(join_form: @join_form, person: Person.new)
  end

  # test "should get index" do
  #   get subscriptions_url
  #   assert_response :success
  # end

  test "should get new" do
    get new_join_path(:en, @union, @join_form)
    assert_response :success
  end

  # test "should create subscription" do
  #   assert_difference('Subscription.count') do
  #     post subscriptions_url, params: { subscription: { account_name: @subscription.account_name, account_number: @subscription.account_number, bsb: @subscription.bsb, ccv: @subscription.ccv, expiry: @subscription.expiry, frequency: @subscription.frequency, join_form_id: @subscription.join_form_id, pay_method: @subscription.pay_method, person_id: @subscription.person_id } }
  #   end

  #   assert_redirected_to subscription_path(Subscription.last)
  # end

  # test "should show subscription" do
  #   get subscription_url(@subscription)
  #   assert_response :success
  # end

  # test "should get edit" do
  #   get edit_subscription_url(@subscription)
  #   assert_response :success
  # end

  # test "should update subscription" do
  #   patch subscription_url(@subscription), params: { subscription: { account_name: @subscription.account_name, account_number: @subscription.account_number, bsb: @subscription.bsb, ccv: @subscription.ccv, expiry: @subscription.expiry, frequency: @subscription.frequency, join_form_id: @subscription.join_form_id, pay_method: @subscription.pay_method, person_id: @subscription.person_id } }
  #   assert_redirected_to subscription_path(@subscription)
  # end

  # test "should destroy subscription" do
  #   assert_difference('Subscription.count', -1) do
  #     delete subscription_url(@subscription)
  #   end

  #   assert_redirected_to subscriptions_path
  # end
end
