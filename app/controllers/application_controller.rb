class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  private
  def find_one_table
    @one_table = current_user.one_tables.where(id: params[:one_table_id]).first
    unless @one_table
      @one_table = OneTable.is_public.find params[:one_table_id]
    end
    @one_table
  end

  def find_site
    @site = current_user.sites.find params[:site_id]
  end

  def require_admin_user
    unless current_user && current_user.admin?
      flash[:notice] = "You must be logged in as admin to access this page"
      redirect_to new_user_session_path
    end
  end

  protected
  def booleanize(value)
    case value
    when '0', 0 then false
    when '1', 1 then true
    else
      value ? true : false
    end
  end
end
