require 'test_helper'
include ActiveJob::TestHelper
include ApplicationHelper
include SubscriptionsHelper

# The subscription controller is very complex, there can be many permutations of join
# New Person
#   Person not found, regular create action is run
#   Person found via API, user logged in, redirect to edit (should have verification screen for logged in user)
#   Person found via API, nothing to reveal, redirect to edit
#   Person found via API, stuff to reveal, inadequate match, existing record missing mandatory fields, use fake values, redirect to verify (need multiple verification options)
#   Person found via API, stuff to reveal, inadequate match, redirect to verify (need multiple verification options)
#   Person found via API, stuff to reveal, inadequate match, nothing to verify with, redirect to create
#   Person verifies by email, updates record (including overwriting fake values), edit is opened
# Update Person
#   Show Step 1 (contact detail fields only) , if existing record using fakes for mandatory fields - This should not be possible unless we send out links to edit
#   Show Step 2 (contact and address fields) , if existing record has contact details fields but no address fields
#   Show Step 3 (contact, address and subscription fields, if existing record has contact and address fields but has no subscription, or a different subscription plan
#   Show Step 4 (contact, address, subscription and payment options), if existing record has contact and address fields, and already has the current subscription plan 
#   Step 3 needs to include the optional plan selection, payment method and the prefered next day of payment, so amount owed, new-financial-date and next-payment-date can be moved to step 4
#   The system needs to be able to tell the difference between having valid payment details vs no payment details
#     Only a person with invalid payment details, or an amount owing should be required to pay
#   If step 3 changes, while step 4 is visible, Either step 4 should be updated by ajax, or step 4 disappears so the user is submitting step 3.
#   When someone makes a payment via direct debit or existing payment method it should be transmitted to membership somehow, and maybe recorded
# API Nuance
#   The system should only fetch from membership, if membership's record is newer (no updated_at in membership) or TTL expired
#   The system shouldn't fetch from membership until any unpushed changes are written
#   The system should be able to proceed without the API being online
#   The system shouldn't keep retrying a disfunctional API (Either API has retry time, or the member's TTL is extended)
#   The system should be able to proceed asynchronously from a push, as the API shant reject changes
#   The system shall be=
# Solution Alternatives
#    Put subscription selection step up front, with pricing.
#    Do not show one long form with sections, instead  
#    After Step 3, the API may need to do a blocking get request (or AJAX request) to workout pricing, next payment days etc...
#    I really need mapping fields, at least in plain text for now.
#    I like GetUp's and the Nurses approach.  Get up starts with email, then only shows those fields thye don't already have.  Though you can signin to see your profile.  The nurses has subscription selection as a first step, with branching questionaire that refreshes after every answer.
# Localise, shows mandarin if enabled, falls back to english when not
# Have to adding mapping fields ASAP, and notification
# SOMETHING HAS CAUSED MY 300 payment to get applied to other records, like it post payments independently of members
# TEST THAT UNAUTHENTICATED PEOPLE CAN'T ACCESS SUBSCRIPTIONS BY ID

#TODO 26 May 2016
# Handle put being called before get
# Test with api being down, returning nil

class SubscriptionsControllerPublicTest < ActionDispatch::IntegrationTest
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

  test "get step 1" do
    get new_join_path(:en, @union, @join_form)
    assert_response :success
    assert response.body.include?('data-step="contact_details"'), "wrong step - should be contact_details"
  end

  test "post step 1 - failure" do
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "", email: "" } }
    assert_response :success
    assert response.body.include?('data-step="contact_details"'), "wrong step - should be contact_details"
    assert response.body.include?('First Name can&#39;t be blank'), "no first_name error"
    assert response.body.include?('Email can&#39;t be blank'), "no email error"
    refute response.body.include?('translation missing'),  'errors have translations' #TODO move to more localisation specific test
  end

  test "post step 1 - success - api finds nothing" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns({})
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au" } }
    assert_response :redirect
    follow_redirect!
    assert response.body.include?('data-step="address"'), "wrong step - should be contact_details"
  end

  test "post step 1 - success, api finds potential member" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215'}))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au" } }
    assert_response :redirect
    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", email: 'lrohde@nuw.org.au'}))
    follow_redirect!
    assert response.body.include?('data-step="address"'), "wrong step - should be contact_details"
  end

  test "post step 2 - trying create twice - shouldn't complain about email being taken" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215'}))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au" } }
    assert_response :redirect
    
    # was breaking on the second attempt because of email validation
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215'}))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au" } }
    assert_response :redirect
    
    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", email: 'lrohde@nuw.org.au'}))
    follow_redirect!
    assert response.body.include?('data-step="address"'), "wrong step - should be contact_details"  
  end

  test "post step 1 - success, someone matched, nothing to reveal" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", email: 'lrohde@nuw.org.au'}))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "lrohde", email: "lrohde@nuw.org.au" } }
    assert_response :redirect
    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", email: 'lrohde@nuw.org.au'}))
    follow_redirect!
    assert response.body.include?('data-step="address"'), "wrong step - should be contact_details"
  end

  test "post step 1 - success, someone matched, identified" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", last_name: 'Rohde', email: 'lrohde@nuw.org.au', mobile: "0439541888", dob: '1978-06-14'}))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: 'Luke', email: 'lrohde@nuw.org.au'})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "Lucas", email: "lrohde@nuw.org.au", 'dob(1i)' =>  '1978', 'dob(2i)' =>  '06', 'dob(3i)' =>  '14' } }
    assert_response :redirect
    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", email: 'lrohde@nuw.org.au'}))
    follow_redirect!
    assert response.body.include?('data-step="address"'), "wrong step - should be contact_details"
  end

  test "post step 1 - success, someone matched, verify" do
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", last_name: 'Rohde', email: 'lrohde@nuw.org.au', mobile: "0439541888", dob: '1978-06-14'}))
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "Lucas", email: "lrohde@nuw.org.au" } }
    assert_response :success
    assert response.body.include?('Please check your email'), "should be verifying"
    assert ActionMailer::Base.deliveries.last.subject == "Please verify your email to continue joining", "verification mail not sent"
  end

  test "post step 1 - success, someone matched, duplicate" do
    mail_count = ActionMailer::Base.deliveries.count
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", last_name: 'Rohde',  mobile: "0439541888", dob: '1978-06-14'}))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns({ external_id: 'NV123456', first_name: "Lucas", email: "lrohde@nuw.org.au", mobile: "0439541888"})
    post new_join_path(:en, @union, @join_form), subscription: { join_form_id: @join_form.id, person_attributes: { first_name: "Lucas", email: "lrohde@nuw.org.au", mobile: "0439541888" } }
    assert_response :redirect
    # TODO Should be a get here but because put is mocked, the member isn't updated with an ID
    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from({external_id: 'NV391215', first_name: "Lucas", email: 'lrohde@nuw.org.au'})) 
    assert ActionMailer::Base.deliveries[-2].subject == "We may be duplicating a member", "duplication mail not sent"
    
    follow_redirect!
    assert response.body.include?('data-step="address"'), "wrong step - should be contact_details"
    end

  def step2_params
    @with_address = people(:contact_details_with_address_person)   
    params = step1_params
    params[:subscription][:person_attributes].merge!(@with_address.attributes.slice('address1', 'address2', 'state', 'suburb', 'postcode'))
    params
  end

  test "get step 2" do 
    @subscription = subscriptions(:contact_details_only_subscription)
    get edit_join_path(:en, @union, @join_form, @subscription.token)
    assert_response :success
    
    assert response.body.include?('data-step="address"'), "wrong step - should be address"
  end

  test "post step 2 - failure" do 
    @without_address = subscriptions(:contact_details_only_subscription)
    params = step1_params
    params[:subscription][:person_attributes][:id] = @without_address.person.id
    patch edit_join_path(:en, @union, @join_form, @without_address.token), params
    assert_response :success
    assert response.body.include?('data-step="address"'), "wrong step - should be address"
    #TODO figure out how to get the address validations to show for person
    assert response.body.include?( I18n.translate('subscriptions.errors.complete_address') ), "no address1 error"
  end

  test "post step 2 - success" do 
    @without_address = subscriptions(:contact_details_only_subscription)
    params = step2_params
    api_params = params[:subscription][:person_attributes].merge!(external_id: 'NV123456')
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns(api_params)
    params[:subscription][:person_attributes][:id] = @without_address.person.id
    mail_count = ActionMailer::Base.deliveries.count
    patch edit_join_path(:en, @union, @join_form, @without_address.token), params
    assert_response :redirect
    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from(api_params))
    follow_redirect!
    assert response.body.include?('data-step="subscription"'), "wrong step - should be subscription"
    assert ActionMailer::Base.deliveries.last.subject.starts_with?("JOIN_FOLLOW_UP:"), "was expecting join follow up email"
  end

  def step3_params
    @with_subscription = subscriptions(:contact_details_with_subscription_subscription)   
    params = step2_params
    params[:subscription].merge!(@with_subscription.slice('plan', 'frequency'))
    params
  end

  test "get step 3" do
    @subscription = subscriptions(:contact_details_with_address_subscription)
    get edit_join_path(:en, @union, @join_form, @subscription.token)

    assert response.body.include?('data-step="subscription"'), "wrong step - should be address"
  end

  test "post step 3 - failure" do 
    with_address = subscriptions(:contact_details_with_address_subscription)
    params = step2_params
    
    params[:subscription][:person_attributes][:id] = with_address.person.id
    patch edit_join_path(:en, @union, @join_form, with_address.token), params
    assert_response :success
    assert response.body.include?('data-step="subscription"'), "wrong step - should be subscription"
    #TODO figure out how to get the address validations to show for person
    assert response.body.include?( 'Payment Frequency can&#39;t be blank') , "no frequency error"
    assert response.body.include?( 'Plan can&#39;t be blank') , "no plan error"
  end


  test "post step 3 - success" do 
    with_address = subscriptions(:contact_details_with_address_subscription)
    params = step3_params
    params[:subscription][:person_attributes][:id] = with_address.person.id
    api_params = params[:subscription][:person_attributes].merge!(external_id: 'NV123456')
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns(api_params)
    patch edit_join_path(:en, @union, @join_form, with_address.token), params
    assert_response :redirect
    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from(api_params))
    follow_redirect!
    assert response.body.include?('data-step="pay_method"'), "wrong step - should be subscription"
  end

  test "get step 4" do
    @subscription = subscriptions(:contact_details_with_subscription_subscription)
    get edit_join_path(:en, @union, @join_form, @subscription.token)

    assert response.body.include?('data-step="pay_method"'), "wrong step - should be pay method"
    assert response.body =~ /I authorize.*100\.00.*9\.99/, "no authorization message"
  end

  test "post step 4 - failure" do 
    with_subscription = subscriptions(:contact_details_with_subscription_subscription)
    params = step3_params
    
    params[:subscription][:person_attributes][:id] = with_subscription.person.id
    patch edit_join_path(:en, @union, @join_form, with_subscription.token), params
    assert_response :success
    assert response.body.include?('data-step="pay_method"'), "wrong step - should be pay_method"
    #TODO figure out how to get the address validations to show for person
    assert response.body.include?( 'Payment Method must be specified') , "no pay method error"
  
    params[:subscription].merge!(pay_method: "CC")
    patch edit_join_path(:en, @union, @join_form, with_subscription.token), params
    assert response.body.include?( "couldn&#39;t be validated by our payment gateway.  Please try again."), "no error for missing stripe token"

    params[:subscription].merge!(pay_method: "AB")
    patch edit_join_path(:en, @union, @join_form, with_subscription.token), params
    assert response.body.include?( "BSB must be properly formatted BSB"), "no error for missing bsb"
    assert response.body.include?( "Account Number must be properly formatted"), "no error for missing account number"
  end

  test "post step 4 - success - australian bank" do 
    @union = @join_form.union
    @union.update( passphrase: '1234567890123456789012345678901234567890', passphrase_confirmation: '1234567890123456789012345678901234567890')
    
    with_subscription = subscriptions(:contact_details_with_subscription_subscription)
    params = step3_params
    
    params[:subscription][:person_attributes][:id] = with_subscription.person.id
    params[:subscription].merge!(pay_method: "AB", bsb: "123-123", account_number: "1231231")

    api_params = params[:subscription][:person_attributes].merge!(external_id: 'NV123456')
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns(api_params)
    
    patch edit_join_path(:en, @union, @join_form, with_subscription.token), params
    assert_response :redirect

    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from(api_params))
    follow_redirect!
    assert response.body.include?('Welcome to the union'), "wrong step - should be welcomed"
    assert ActionMailer::Base.deliveries.last.subject.starts_with?("JOIN:"), "was expecting a join email"
  end
  
  test "post step 4 - success - credit card" do 
    @union = @join_form.union
    @union.update( passphrase: '1234567890123456789012345678901234567890', passphrase_confirmation: '1234567890123456789012345678901234567890')
    
    with_subscription = subscriptions(:contact_details_with_subscription_subscription)
    params = step3_params
    
    params[:subscription][:person_attributes][:id] = with_subscription.person.id
    params[:subscription].merge!(pay_method: "CC", expiry_year: "2018", expiry_month: "06", card_number: "12341234123141234", stripe_token: "asdfasdf")

    Stripe::Customer.expects(:create).returns (OpenStruct.new(id: 123))
    Stripe::Charge.expects(:create).returns (true)
    
    api_params = params[:subscription][:person_attributes].merge!(external_id: 'NV123456')
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns(api_params)
    
    patch edit_join_path(:en, @union, @join_form, with_subscription.token), params
    assert_response :redirect

    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from(api_params))
    follow_redirect!
    
    assert response.body.include?('Welcome to the union'), "wrong step - should be welcomed"
  end

  test "get form with column list" do
    @subscription = subscriptions(:column_list)
    get edit_join_path(:en, @union, @subscription.join_form, @subscription.token)

    assert response.body.include?('subscription[data[worksite]]'), "missing custom worksite field"
    assert response.body.include?('subscription[data[worksite]]'), "missing custom employer field"
    assert response.body.include?('nuw bourke street'), "missing custom worksite value"
    assert response.body.include?('freechange'), "missing custom employer value"
  end

  test "post form with column list - failure" do 
    @subscription = subscriptions(:column_list)
    params = step3_params
    params[:subscription][:join_form_id] = @subscription.join_form_id
    params[:subscription][:person_attributes][:id] = @subscription.person.id
    params[:subscription][:data] = {}
    params[:subscription][:data][:worksite] = ""
    params[:subscription][:data][:employer] = ""
    
    patch edit_join_path(:en, @union, @subscription.join_form, @subscription.token), params
    assert_response :success
    
    assert response.body.include?('data-step="subscription"'), "wrong step - should be subscription"
    #TODO figure out how to get the address validations to show for person
    assert response.body.include?( 'Worksite can&#39;t be blank') , "no worksite error"
    assert response.body.include?( 'Employer can&#39;t be blank') , "no employer error"
  end
 

  test "post form with column list - success" do 
    @subscription = subscriptions(:column_list)
    params = step3_params
    params[:subscription][:join_form_id] = @subscription.join_form_id
    params[:subscription][:person_attributes][:id] = @subscription.person.id
    params[:subscription][:data] = {}
    params[:subscription][:data][:worksite] = "asdf_w"
    params[:subscription][:data][:employer] = "asdf_e"
    
    patch edit_join_path(:en, @union, @subscription.join_form, @subscription.token), params
    assert_response :redirect
    
    @subscription.reload
    assert @subscription.data["worksite"] == "asdf_w", "custom column worksite didn't update"
    assert @subscription.data["employer"] == "asdf_e", "custom column employer didn't update"
  end
 

  # test "post form with column list - success" do 
  #   with_address = subscriptions(:contact_details_with_address_subscription)
  #   params = step3_params
  #   params[:subscription][:person_attributes][:id] = with_address.person.id
  #   api_params = params[:subscription][:person_attributes].merge!(external_id: 'NV123456')
  #   SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns(api_params)
  #   patch edit_join_path(:en, @union, @join_form, with_address.token), params
  #   assert_response :redirect
  #   #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nuw_end_point_transform_from(api_params))
  #   follow_redirect!
  #   assert response.body.include?('data-step="pay_method"'), "wrong step - should be subscription"
  # end


  # TODO I think i have a bug in here, where the subscription join form can vary from the joinform shown
  # TODO testing around first_payment

  # TODO why did email, firstname, lastname, dob not ask to verify
  # TODO make address updates consistent so address2 isn't left behind
  # TODO if it matches me, but doesn't show it, because I'm potential, should I send a warning?
  # TODO add status change notes
  # TODO why did the tests not pickup the missing application helper for verify email?


# Person.all.order(:created_at).map{|p| 
#   p
#   .slice(:created_at, :external_id, :first_name, :last_name, :email, :mobile)
#   .merge((p.subscriptions.last.slice(:frequency) rescue {}))
#   .merge((p.subscriptions.last.join_form.slice(:short_name) rescue {}))
#   #.merge(amount: p.payments.sum(:amount))
# }
end
