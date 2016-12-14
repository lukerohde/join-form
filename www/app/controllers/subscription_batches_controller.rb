class SubscriptionBatchesController < ApplicationController
  
  #before_action :authenticate_person!, except: [:show, :new, :create, :edit, :update, :renew]
  
  skip_before_action :authenticate_person!, if: :api_request?
  skip_before_action :verify_authenticity_token, if: :api_request?, only: [:create]
  before_filter :verify_hmac, if: :api_request?, only: [:create]
  
  before_action :set_join_form, only: [:create]
  
  include SubscriptionsHelper

  def create
    request.body.rewind # needed for integration test
    
    data = check_signature(JSON.parse(request.body.read)) # check it again only to remove the hmac
    @subscriptions = nuw_end_point_receive(data, @join_form)
    
    # save an array of subscriptions
    success = [false]
    begin
      Subscription.transaction do 
        success = @subscriptions.map(&:save_without_validation!)
        raise ActiveRecord::Rollback unless success.all?
      end 
    rescue
    end
    
    respond_to do |format|
      if success.all?
        format.json { render :index }
      else
        format.json { render json: @subscriptions.select {|s| !s.errors.blank?}, status: :unprocessable_entity }
      end
    end
  end
end 
