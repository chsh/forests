class EntryWrapper
  def initialize(name, io)
    @name = name
    @io = io
  end
  def name; @name; end
  def read(*args); @io.read(*args); end
  def name=(value)
    @name = value
  end
  def io=(value)
    @io = value
  end
  def id; @name; end
end
