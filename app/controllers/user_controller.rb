# -*- coding: utf-8 -*-
class UserController < ApplicationController

  before_filter :authenticate_user!

  def show
    @user = current_user
  end
  def dashboard
    redirect_to one_tables_path
#    @user = current_user
#    render :action => "dashboard_#{@user.level_as_string}"
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "ユーザ情報が更新されました"
      redirect_to root_url
    else
      render :action => :edit
    end
  end

  def confirm
    @user = User.new
  end

end
