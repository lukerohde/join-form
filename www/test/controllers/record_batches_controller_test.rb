require 'test_helper'

class RecordBatchesControllerTest < ActionDispatch::IntegrationTest
# class RecordBatchesControllerTest < ActionController::TestCase
  # include Devise::TestHelpers

  def sign_in_admin
    @admin = people(:admin)
    sign_in @admin
  end

  setup do
    sign_in_admin
    @record_batch = record_batches(:one)
    @join_form = join_forms(:one)
    @union = @join_form.union
    @has_mobile = subscriptions(:has_mobile)
    @has_email= subscriptions(:has_email)
  end

  test "should get index" do
    get union_join_form_record_batches_url(union_id: @union, join_form_id: @join_form)
    assert_response :success
    assert_not_nil assigns(:record_batches)
  end 

  test "should get new" do
    get new_union_join_form_record_batch_url(union_id: @union, join_form_id: @join_form)
    assert_response :success
  end

  test "should create record_batch" do
    assert_difference('RecordBatch.count') do
      assert_difference('Record.count',3) do 
        assert_difference('ActionMailer::Base.deliveries.count',5) do  # 2 emails, 2 filing emails, 1 SMS filing email
          post union_join_form_record_batches_url(union_id: @union.id, join_form_id: @join_form.id, params: { record_batch: { email_template_id: @record_batch.email_template_id, name: @record_batch.name, sms_template_id: @record_batch.sms_template_id }, subscription_ids: [@has_mobile.id, @has_email.id] })
          # post :create, union_id: @union, join_form_id: @join_form, record_batch: { email_template_id: @record_batch.email_template_id, name: @record_batch.name, sms_template_id: @record_batch.sms_template_id }, subscription_ids: [@has_mobile.id, @has_email.id]
        end
      end
    end

    r = assigns(:record_batch)
    assert_redirected_to union_join_form_record_batch_path(r.join_form.union, r.join_form, r)
    assert_equal @admin.email, r.sender.email
  end

  test "should show record_batch" do
    get union_join_form_record_batch_url(union_id: @union, join_form_id: @join_form, id: @record_batch)
    # get :show, union_id: @union, join_form_id: @join_form, id: @record_batch
    assert_response :success
  end

  test "should destroy record_batch" do
    assert_difference('RecordBatch.count', -1) do
      delete union_join_form_record_batch_url(union_id: @union, join_form_id: @join_form, id: @record_batch)
    end

    assert_redirected_to union_join_form_record_batches_path(union_id: @union, join_form_id: @join_form)
  end
end
