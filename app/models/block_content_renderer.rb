# encoding: UTF-8
# 1レコードをcontentを使ってレンダリングします。
class BlockContentRenderer
  def initialize(content, content_type)
    @content = content
    if html? content_type
      @is_html = true
    end
  end
  def render(rec = nil)
    return @content unless rec
    if @is_html
      render_as_html(rec)
    else
      render_plain_text(rec)
    end
  end

  private
  def render_as_html(rec)
    @content.gsub(/\b_([^_]+)_\b/) do |match|
      viewable rec, $1
    end
  end
  def render_plain_text(rec)
    @content.gsub(/\b_([^_]+)_\b/) do |match|
      viewable rec, $1
    end
  end
  def html?(content_type)
    return true if content_type == 'text/html'
    false
  end
  def viewable(rec, key)
    key = '_id' if key == 'ID'
    value = rec[key]
    return '' if value.blank?
    return jdate(value) if value.is_a? Time
    return image(value) if value.is_a?(Hash) && value.path('/metadata/width')
    value.to_s
  end
  JWDAYS = '日月火水木金土日'.split(//)
  def jdate(time)
    lt = time.getlocal
    sprintf('%d年%d月%d日(%s)', lt.year, lt.month, lt.day, JWDAYS[lt.wday])
  end
  def image(value)
    w = value.path('/metadata/width'); h = value.path('/metadata/height')
    otid = value.path('/metadata/id/')
    path = value.path('/value')
    "<img src=\"/files/#{otid}/#{path}\"/>"
  end
end
