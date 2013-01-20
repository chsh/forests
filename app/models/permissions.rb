class Permissions
  def initialize(user)
    @user = User.find(user)
  end

  def assign(*args)
    proxy(:assign, *args)
  end

  def unassign(*args)
    proxy(:unassign, *args)
  end

  def accessible_instances(model)
    return model.all if @user.admin?
    assigned_instances(model) + owned_instances(model)
  end

  def assigned_instances(model)
    proxy(:assigned_instances, model)
  end

  def owned_instances(model)
    mn = model.to_s.underscore.pluralize
    if @user.respond_to? mn
      @user.send(mn).map do |it|
        it.permission = UserModelPermission::Permission.new(UserModelPermission::EVERYTHING) if it.respond_to?('permission=')
        it
      end
    else
      []
    end
  end

  def creatable?(*models)
    models.each do |model|
      mt = model.to_s.classify
      return true if ['Site', 'OneTable'].include?(mt) && @user.level >= User::LEVEL_SITEADMIN
    end
    permission_available?(:creatable, *models)
  end
  def editable?(*models)
    permission_available?(:editable, *models)
  end
  def viewable?(*models)
    permission_available?(:viewable, *models)
  end
  def removable?(*models)
    permission_available?(:removable, *models)
  end

  def size
    proxy(:size)
  end

  def reload!
    umps(true)
  end

  def owned?(model)
    return true if model.respond_to?(:user_id) && model.send(:user_id) == @user.id
    return true if model.respond_to?(:owner?) && model.send(:owner?, @user)
    false
  end
  private
  def proxy(method, *args)
    umps.send method, *args
  end
  def umps(reload = false)
    @user.user_model_permissions(reload)
  end
  def permission_available?(target, *models)
    return true if @user.admin?
    [models].flatten.each do |model|
      return true if (proxy("#{target}?", model) || owned?(model))
    end
    false
  end
end
