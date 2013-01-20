class Static
  def self.method_missing(meth, *args)
    if class_config.respond_to? meth
      self.class_eval %{
        def self.#{meth}
          class_config.#{meth}
        end
      }, __FILE__, __LINE__
      self.send meth, *args
    else
      super meth, *args
    end
  end
end
