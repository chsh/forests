class MetaString < String
  def self.from(string, opts = {})
    ms = new(string)
    ms.metadata = opts
    ms
  end
  def metadata
    @metadata ||= {}
  end
  def metadata=(value)
    @metadata = value
  end
end
