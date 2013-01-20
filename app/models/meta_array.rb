class MetaArray < Array
  def self.from(array, opts = {})
    ma = new(array)
    ma.metadata = opts
    ma
  end
  def metadata
    @metadata ||= {}
  end
  def metadata=(value)
    @metadata = value
  end
end
