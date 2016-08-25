require 'test_helper'


class SubscriptionsControllerTest < ActionController::TestCase
	include Devise::TestHelpers

	def sign_in_admin
		@admin = people(:admin)
		sign_in @admin
	end

  test "subscriptions list - not logged in" do
  	get :index
    assert_response :redirect
    assert response.body.include?(new_person_session_url(locale:nil)), "not redirected to sign in"
  end


  test "subscriptions list - logged in" do
  	sign_in_admin
  	get :index
    assert_response :success
    s = subscriptions(:one)
    assert response.body.include?(edit_join_path(union_id: s.join_form.union.short_name, join_form_id: s.join_form.short_name, id: s.token)
), "subscription not listed"
  end

  test "subscriptions list - logged in, renewal and source check" do
    sign_in_admin
    get :index
    assert_response :success
    assert response.body.include?('RENEWAL'), "renewal not listed"
    assert response.body.include?('nuw-api'), "nuw-api source not listed"
    assert response.body.include?('facebook.com'), "facebook source not listed"
  end

  test "subscriptions list - don't show other unions subscriptions" do
  	skip("Not implemented")
  end

end
