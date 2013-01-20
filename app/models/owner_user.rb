class OwnerUser < ActiveRecord::Base
  belongs_to :owner, :class_name => 'User'
  belongs_to :user

  before_save :fill_user_and_verify_owner
  def fill_user_and_verify_owner
    if @user_email && self[:user_id].blank?
      u = User.find_by_email(@user_email)
      self[:user_id] = u.id if u
    end
    raise "Same owner and user is not allowed." if self[:owner_id] == self[:user_id]
  end

  def user_email=(email)
    @user_email = email
  end
  def user_email
    @user_email ||= build_user_email
  end
  private
  def build_email
    return nil unless self.user
    self.user.email
  end
end
