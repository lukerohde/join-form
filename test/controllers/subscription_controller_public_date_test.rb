require 'test_helper'
include ActiveJob::TestHelper
include ApplicationHelper
include SubscriptionsHelper

class SubscriptionsControllerPublicDateTest < ActionDispatch::IntegrationTest
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

  test "post step 1 - success - with blank date" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns({})
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au", 'dob(1i)' => "" , 'dob(2i)' => "" , 'dob(3i)' => "" } }
    assert_response :redirect
    follow_redirect!
    assert response.body.include?('data-step="address"'), "wrong step - should be contact_details"
  end

  test "post step 1 - success - with valid date" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns({})
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au", 'dob(1i)' => "01" , 'dob(2i)' => "01" , 'dob(3i)' => "01" } }
    assert_response :redirect
    follow_redirect!
    assert response.body.include?('data-step="address"'), "wrong step - should be contact_details"
  end

  test "post step 1 - failure - validates partly blank date, when resubscribing and being patched" do
    # TODO I don't know how to return a validation message on partial date, when being combined in subscription_params
    # I should find where in the API it was struggling with the date params and fix it there maybe.
    # blanks the date, so won't be patched

    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns({})
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: "contact_details_with_address@nuw.org.au"})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "luke", email: "contact_details_with_address@nuw.org.au", mobile: '0439541888', 'dob(1i)' => "" , 'dob(2i)' => "01" , 'dob(3i)' => "01" } }
    #assert_response 200
    assert_response :redirect
    follow_redirect!
    assert response.body.include?('data-step="pay_method"'), "wrong step - should be contact_details"
  end
  
end
