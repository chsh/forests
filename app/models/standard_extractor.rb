class StandardExtractor
  def self.from(content, content_type)
    new(content, content_type)
  end
  def initialize(content, content_type)
    @content = content
    @content_type = content_type
    @renderer = BlockContentRenderer.new(@content, @content_type)
  end
  def render(rec, opts = {})
    if rec.is_a? Array
      rec_contents = rec.map do |r|
        render_ r
      end
      rec_contents.join('')
    else
      render_ rec
    end
  end
  private
  def render_(rec)
    @renderer.render rec
  end
end
