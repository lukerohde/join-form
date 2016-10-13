require 'test_helper'

class RecordBatchesControllerTest < ActionController::TestCase
  setup do
    @record_batch = record_batches(:one)
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
      post :create, record_batch: { email_template_id: @record_batch.email_template_id, name: @record_batch.name, sms_template_id: @record_batch.sms_template_id }
    end

    assert_redirected_to record_batch_path(assigns(:record_batch))
  end

  test "should show record_batch" do
    get :show, id: @record_batch
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @record_batch
    assert_response :success
  end

  test "should update record_batch" do
    patch :update, id: @record_batch, record_batch: { email_template_id: @record_batch.email_template_id, name: @record_batch.name, sms_template_id: @record_batch.sms_template_id }
    assert_redirected_to record_batch_path(assigns(:record_batch))
  end

  test "should destroy record_batch" do
    assert_difference('RecordBatch.count', -1) do
      delete :destroy, id: @record_batch
    end

    assert_redirected_to record_batches_path
  end
end
