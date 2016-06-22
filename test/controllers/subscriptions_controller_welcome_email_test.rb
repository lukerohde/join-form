require 'test_helper'
include ActiveJob::TestHelper
include ApplicationHelper
include SubscriptionsHelper

class SubscriptionsControllerWelcomeEmailTest < ActionDispatch::IntegrationTest
  setup do
    @join_form = join_forms(:welcome)
    @union = @join_form.union
    @new_subscription = Subscription.new(join_form: @join_form, person: Person.new)
    @with_address = people(:contact_details_with_address_person)   
    @with_subscription = subscriptions(:contact_details_with_subscription_subscription)   
    people(:admin).follow!(@join_form)
    WickedPdf.any_instance.stubs(:pdf_from_url).returns("PDF MOCK")
  end


  def form_params
    params = { subscription: 
      { 
        join_form_id: @join_form.id, 
        person_attributes: 
        { 
          email: 'lrohde@nuw.org.au', 
          first_name: 'mr luke' 
        } 

      } 
    }
    params[:subscription][:person_attributes].merge!(@with_address.attributes.slice('address1', 'address2', 'state', 'suburb', 'postcode'))
    params[:subscription][:person_attributes][:id] = @with_subscription.person.id
    params[:subscription].merge!(@with_subscription.slice('plan', 'frequency'))
    params[:subscription].merge!(pay_method: "AB", bsb: "123-123", account_number: "1231231")
    params
  end


  test "post step 4 - success - australian bank" do 
    @union = @join_form.union
    @union.update( passphrase: '1234567890123456789012345678901234567890', passphrase_confirmation: '1234567890123456789012345678901234567890')
    
    params = form_params
    api_params = params[:subscription][:person_attributes].merge!(external_id: 'NV123456')
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns(api_params)
    
    starting_email_count = ActionMailer::Base.deliveries.count
    patch edit_join_path(:en, @union, @join_form, @with_subscription.token), params
    assert_response :redirect

    assert ActionMailer::Base.deliveries.count == starting_email_count + 2, "was expecting two emails to be sent"
    assert ActionMailer::Base.deliveries.last.subject.starts_with?("welcome mr luke"), "was expecting a welcome email"
    assert ActionMailer::Base.deliveries.last.to.include?("lrohde@nuw.org.au"), "was expecting a welcome email to send to lrohde@nuw.org.au"
  end

  
end