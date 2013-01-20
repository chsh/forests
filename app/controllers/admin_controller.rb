class AdminController < ApplicationController
  before_filter :require_admin_user
  def show
  end
end
