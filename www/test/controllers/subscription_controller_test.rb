require 'test_helper'


class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  # include Devise::TestHelpers

  def sign_in_admin
    @admin = people(:admin)
    sign_in @admin
  end

  def setup
    @union = supergroups(:owner)
    @join_form = @union.join_forms.first
  end

  test "subscriptions list - not logged in" do
    get union_join_form_subscriptions_url(union_id: @union, join_form_id: @join_form)

    assert_response :redirect
    assert response.body.include?(new_person_session_url(locale:nil)), "not redirected to sign in"
  end


  test "subscriptions list - logged in" do
    sign_in_admin
    get union_join_form_subscriptions_url(union_id: @union, join_form_id: @join_form)

    assert_response :success
    s = subscriptions(:one)
    assert response.body.include?(edit_join_path(union_id: s.join_form.union.short_name, join_form_id: s.join_form.short_name, id: s.token)), "subscription not listed"
  end

  test "subscriptions list - search for join form" do
    sign_in_admin
    get union_join_form_subscriptions_url(union_id: @union, join_form_id: @join_form,
      subscription_search: { keywords: "SearchString", renewal: "0",
      from: "2016-10-31", to: "2016-11-07" })

    assert_response :success
    excluded_subscription = subscriptions(:search_subscription_complete)
    included_subscription = subscriptions(:search_subscription_fresh)

    refute response.body.include?(excluded_subscription.source), "renewal subscriptions should not be present"
    assert response.body.include?(included_subscription.source), "fresh subscriptions should be present"
  end

  test "subscriptions list - logged in, renewal and source check" do
    sign_in_admin
    get union_join_form_subscriptions_url(union_id: @union, join_form_id: @join_form)
    assert_response :success
    assert response.body.include?('RENEWAL'), "renewal not listed"
    assert response.body.include?('nuw-api'), "nuw-api source not listed"
    assert response.body.include?('facebook.com'), "facebook source not listed"
  end

  test "subscriptions list - don't show other unions subscriptions" do
    skip("Not implemented")
  end

end
