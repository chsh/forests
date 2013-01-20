# -*- coding: utf-8 -*-
class Users::SessionsController < Devise::SessionsController
  def create
    u = User.find_by_login params[:user][:login]
    if u.present? && u.level == User::LEVEL_INACTIVE
      flash[:error] = "該当ユーザはアカウントが無効です。"
      render action: 'new'
      return
    end
    super
  end
end
