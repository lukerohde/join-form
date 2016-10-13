require 'test_helper'

class RecordBatchesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def sign_in_admin
    @admin = people(:admin)
    sign_in @admin
  end

  setup do
    sign_in_admin
    @record_batch = record_batches(:one)
    @has_mobile = subscriptions(:has_mobile)
    @has_email= subscriptions(:has_email)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:record_batches)
  end 

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create record_batch" do
    assert_difference('RecordBatch.count') do
      assert_difference('Record.count',3) do 
        assert_difference('ActionMailer::Base.deliveries.count',5) do  # 2 emails, 2 filing emails, 1 SMS filing email
          post :create, record_batch: { email_template_id: @record_batch.email_template_id, name: @record_batch.name, sms_template_id: @record_batch.sms_template_id }, subscription_ids: [@has_mobile.id, @has_email.id]
        end
      end
    end

    assert_redirected_to record_batch_path(assigns(:record_batch))
  end

  test "should show record_batch" do
    get :show, id: @record_batch
    assert_response :success
  end

  test "should destroy record_batch" do
    assert_difference('RecordBatch.count', -1) do
      delete :destroy, id: @record_batch
    end

    assert_redirected_to record_batches_path
  end
end
