class AdminOption < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true

  serialize :attrs, HashWithIndifferentAccess

  def []=(key, value)
    if has_attribute? key
      super(key, value)
    else
      attrs[key] = value
    end
  end

  def [](key)
    if has_attribute? key
      super(key)
    else
      attrs[key]
    end
  end

  def method_missing(meth, *args)
    ms = meth.to_s
    if ms[0] == '_'
      super(meth, *args)
    elsif ms =~ /^(.+)=$/
      ms = $1
      self.attrs[ms] = args[0]
    elsif self.attrs.key?(ms)
      self.attrs[ms]
    else
      super(meth, *args)
    end
  end
end
