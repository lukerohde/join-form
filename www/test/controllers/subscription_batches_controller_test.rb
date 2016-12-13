require 'test_helper'
include ActiveJob::TestHelper

class SubscriptionBatchesControllerTest < ActionDispatch::IntegrationTest

	setup do
    @join_form = join_forms(:one)
    @union = @join_form.union
	end 

  test "post step 2 - api" do
    payload = [ { external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au', subscription: {source: 'nuw-api'}} ]
    SubscriptionBatchesController.any_instance.stubs(:check_signature).returns(payload)
  	SubscriptionBatchesController.any_instance.stubs(:verify_hmac).returns(payload)
  
    post union_join_form_subscription_batches_path( :en, @union, @join_form, format: 'json'), payload.to_json
    
    assert Subscription.last.renewal == true, "Should be a renewal"
    assert Subscription.last.source == "nuw-api", "Source should be nuw-api"
    assert Subscription.last.pending == true, "Pending should be true"
  end
end
