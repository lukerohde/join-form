require 'test_helper'
include ActiveJob::TestHelper
include ApplicationHelper
include SubscriptionsHelper

class SubscriptionsControllerFacebookPageTab < ActionDispatch::IntegrationTest
  setup do
    @join_form = join_forms(:one)
    @union = @join_form.union
  end

  #test "facebook page tab, post, redirect to new" do
  #  post new_join_path(:en, @union, @join_form), {signed_request: "asdfadsfasdf" }, {'HTTP_REFERER' => 'https://staticxx.facebook.com/platform/page_proxy/hv09mZVdEP8.js'}
  #  assert_redirected_to new_join_path(:en, @union, @join_form)
  #end

  test "facebook page tab, post, render new" do
   post new_join_path(:en, @union, @join_form), {signed_request: "asdfadsfasdf" }, {'HTTP_REFERER' => 'https://staticxx.facebook.com/platform/page_proxy/hv09mZVdEP8.js'}
   assert_response :success
   assert_template :new
  end

  
end
