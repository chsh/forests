class FormExtractor
  def self.from(source)
    new(source)
  end
  def initialize(content)
    @content = content
  end
  def render(records, opts = {})
    @content
  end
end
