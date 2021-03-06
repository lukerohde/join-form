class ApplicationController < ActionController::Base
  include ApplicationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_person!
  before_action :set_union
  before_action :set_locale

  def set_locale
    l = params[:locale] || "en"
    l = l.gsub('-', '_').downcase # convert zh-TW to zh_tw, a more sane symbol
    l = "en" if l == "en_au"
    l = l.to_sym

    I18n.locale = l #if params[:locale].present?
  end

  def default_url_options(options={})
    { locale: I18n.locale }.merge options
  end

  def not_found
  	render(:file => File.join(Rails.root, 'public/404.html'), :status => 404, :layout => false)
	end

  def forbidden
  	render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
	end

  def bad_request
      render(:file => File.join(Rails.root, 'public/400.html'), :status => 400, :layout => false)
  end

  def set_union
    id = params[:union_id] || (params[:controller]=="supergroups" ? params[:id] : nil) 
    id ||= owner_union.id
    
    if (Integer(id) rescue nil)
      @union = Supergroup.find(id)
    else
      @union = Supergroup.where("short_name ilike ?",id.downcase).first
    end
  end
  
  private
  def api_request?
    request.format.json? || request.format.xml?
  end
  
  def verify_hmac
    SignedRequest.check_signature(ENV['NUW_END_POINT_SECRET'], JSON.parse(request.body.read), request.original_url)
  rescue SignedRequest::SignatureMismatch
    forbidden
  end

   def check_signature(payload)
    SignedRequest.check_signature(ENV['NUW_END_POINT_SECRET'], payload, request.original_url)
  rescue SignedRequest::SignatureMismatch
    forbidden
  end
end
