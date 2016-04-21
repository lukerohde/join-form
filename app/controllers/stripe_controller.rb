class StripeController < ApplicationController
  include StripeHelper

  def index
  	union = Union.find(params[:state])
  	token = get_stripe_token(params[:code])
  	
  	unless token["error"]
  		if union.update(stripe_params(token))
  			redirect_to edit_union_path(union), notice: "Your stripe account has been successfully connected"
  		else
  			redirect_to edit_union_path(union), notice: "Something went wrong! Error: #{union.errors}"
  		end
  	else
  		redirect_to union, notice: "Something went wrong! Response: #{token['error']} Message: #{token['error_description']}"
  	end
  end

  def destroy
  	union = Union.find(params[:id])
  	if deauthorize_stripe_user_id(union.stripe_user_id)
  		union.update(blank_stripe_params)
  		redirect_to edit_union_path(union), notice: "Your stripe account has been disconnected."
  	else 
  		redirect_to edit_union_path(union), notice: "Something went wrong disconnecting your stripe account."
  	end
  end

  def stripe_params(params)
  	{
  		stripe_access_token: params['access_token'],
  		stripe_refresh_token: params['refresh_token'],
  		stripe_publishable_key: params['stripe_publishable_key'],
  		stripe_user_id: params['stripe_user_id']
  	}
  end

  def blank_stripe_params
  	{
			stripe_access_token: nil, 
  		stripe_refresh_token: nil, 
  		stripe_publishable_key: nil, 
  		stripe_user_id: nil
   	}
  end
end
