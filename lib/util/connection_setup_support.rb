
require 'digest/sha1'

module ConnectionSetupSupport
  def initial_setup
    if self.count == 0
      self.create self.class_config['default']
    end
  end
end
