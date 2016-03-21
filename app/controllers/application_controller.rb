class ApplicationController < ActionController::Base
  include ApplicationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_person!
  before_action :set_union

  def not_found
  	render(:file => File.join(Rails.root, 'public/404.html'), :status => 404, :layout => false)
	end

  def forbidden
  	render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
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
end
