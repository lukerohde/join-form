require 'test_helper'
include ActiveJob::TestHelper
include ApplicationHelper
include SubscriptionsHelper

class SubscriptionBatchesControllerAPITest < ActionDispatch::IntegrationTest
  setup do
    @join_form = join_forms(:one)
    @union = @join_form.union
    @new_subscription = Subscription.new(join_form: @join_form, person: Person.new)
    people(:admin).follow!(@join_form)
    WickedPdf.any_instance.stubs(:pdf_from_url).returns("PDF MOCK")
  end

  def api_params
    { email: 'lrohde@nuw.org.au', first_name: 'luke' }
  end

  test "forbid unsigned api post" do
    #post "/nuw/#{@join_form.short_name}/renew.json", api_params.to_json
    post "/unions/nuw/join_forms/#{@join_form.short_name}/subscription_batches.json", api_params.to_json
    assert_response :forbidden
  end

  test "allow unsigned api post" do
    post "/unions/nuw/join_forms/#{@join_form.short_name}/subscription_batches.json", api_params.to_json
    params = SignedRequest::sign(ENV['NUW_END_POINT_SECRET'],api_params, "http://www.example.com#{path}")
    post path, params.to_json

    assert_response :success
  end

end
