require 'test_helper'
include ActiveJob::TestHelper
include ApplicationHelper
include SubscriptionsHelper

class SubscriptionsControllerSourceTest < ActionDispatch::IntegrationTest
  setup do
    @join_form = join_forms(:one)
    @union = @join_form.union
    @new_subscription = Subscription.new(join_form: @join_form, person: Person.new)
    people(:admin).follow!(@join_form)
    WickedPdf.any_instance.stubs(:pdf_from_url).returns("PDF MOCK")
  end

  def step1_params
    { subscription: 
      { 
        join_form_id: @join_form.id, 
        person_attributes: 
        { 
          email: 'lrohde@nuw.org.au', 
          first_name: 'luke' 
        } 

      } 
    }
  end

  test "get step 1 - with source" do
    get new_join_path(:en, @union, @join_form, source: "sms")
    assert_response :success
    assert response.body.include?('data-step="contact_details"'), "wrong step - should be contact_details"
    assert response.body.include?('value="sms"'), "hidden source not included"
  end

  test "get step 1 - without source" do
    get new_join_path(:en, @union, @join_form), {}, {'HTTP_REFERER' => 'http://foo.com'}
    assert_response :success
    assert response.body.include?('data-step="contact_details"'), "wrong step - should be contact_details"
    assert response.body.include?('value="http://foo.com"'), "hidden source not included"
  end

  test "post step 2 - source persists" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215'}))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { source: 'sms', join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au" } }
    assert_response :redirect
    follow_redirect! 
    assert response.body.include?('value="sms"'), "hidden source not included"
  end

  test "post step 2 - renewal" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215'}))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au" } }
    
    assert Subscription.last.renewal == true
  end

  test "post step 2 - no renewal" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns({})
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au" } }
    
    assert Subscription.last.renewal == false
  end

  test "post step 2 - api" do
    SubscriptionsController.any_instance.stubs(:check_signature).returns("true")
  
    post new_renewal_path( :en, @union, @join_form, format: 'json'), { subscription: { external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'} }.to_json
    
    assert Subscription.last.renewal == true
    assert Subscription.last.source == "nuw-api"
  end

end
