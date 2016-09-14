require 'test_helper'

class RecordsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def sign_in_admin
    @admin = people(:admin)
    sign_in @admin
  end

  setup do
    sign_in_admin
    @record = records(:one)
    @subscription = subscriptions(:one)
  end

  test "should get new" do
    get :new, subscription_id: @subscription.id
    assert_response :success
  end

  test "should create sms record" do
    assert_difference('Record.count') do
      post :create, subscription_id: @subscription.id, record: { body_plain: @record.body_plain, subject: @record.subject, template_id: @record.template_id, type: 'SMS' }
    end
    assert_redirected_to new_subscription_record_path(@subscription) + "?type=SMS"
  end

  test "should create email record" do
    
    assert_difference('ActionMailer::Base.deliveries.count', 2) do 
      assert_difference('Record.count') do
        post :create, subscription_id: @subscription.id, record: { body_plain: @record.body_plain, subject: @record.subject, template_id: @record.template_id, type: 'Email' }
      end
    end

    assert_redirected_to new_subscription_record_path(@subscription) + "?type=Email"
  end



  test "should forward reply email" do
    #sign_out

    assert_difference('ActionMailer::Base.deliveries.count', 2) do 
      assert_difference('Record.count') do
        post 'receive_email', { Subject: 'test', Body: 'hi', Sender: 'lrohde@nuw.org.au', 'In-Reply-To': '1234@1234' }
      end
    end

    assert_response :success
  end

  test "should forward reply sms" do
    #sign_out
    assert_difference('ActionMailer::Base.deliveries.count', 2) do 
      assert_difference('Record.count') do
        post 'receive_sms', { Body: 'hi', From: '+61439541888' }
      end
    end

    assert_response :success
  end


  test "should update sms delivery status" do
    #sign_out
    post 'update_sms', { id: @record.id, MessageStatus: "sent" }
    
    @record.reload
    assert @record.delivery_status == "sent", 'sms delivery Status not updated'
  
    assert_response :success
  end

  test "should update email delivery status" do
    #sign_out
    post 'update_email', { 'Message-Id': "1234@1234", event: "sent" }
    
    @record.reload
    assert @record.delivery_status == "sent", 'sms delivery Status not updated'
  
    assert_response :success
  end

  #test "should show record" do
  #  get :show, subscription_id: @subscription.id, id: @record
  #  assert_response :success
  #end

  test "should destroy record" do
    assert_difference('Record.count', -1) do
      delete :destroy, subscription_id: @subscription.id, id: @record
    end

    assert_redirected_to new_subscription_record_url(@subscription)
  end
end
