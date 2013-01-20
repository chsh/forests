class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.admin?
      can :manage, :all
      can :view, OneTable
      can :edit, OneTable
      can :remove, OneTable
      can :copy, OneTable
    elsif user.has_role? :data_viewable, OneTable
      can :view, OneTable
    elsif user.has_role? :data_editable, OneTable
      can :view, OneTable
      can :edit, OneTable
    elsif user.has_role? :data_removable, OneTable
      can :view, OneTable
      can :edit, OneTable
      can :remove, OneTable
      can :copy, OneTable
    end

  end
end
