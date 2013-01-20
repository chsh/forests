module ApplicationHelper
  def error_messages(form)
    if form.errors.any?
      raw "<ul>" + form.errors.full_messages.map { |msg| "<li>#{msg}</li>" }.join('') + "</ul>"
    end
  end

  def icon_tag(name, style_attrs = {}, tag_attrs = {})
    _icon_tag [name], style_attrs, tag_attrs
  end

  def large_icon_tag(name, style_attrs = {}, tag_attrs = {})
    _icon_tag [name, :large], style_attrs, tag_attrs
  end

  private
  def build_style(style_attrs)
    ary = []
    style_attrs.each do |k, v|
      ary << "#{k}: #{v}"
    end
    { style: ary.join(';') }
  end
  def _icon_tag(names, style_attrs, tag_attrs)
    class_names = names.map do |name|
      'icon-' + name.to_s.gsub(/_/, '-')
    end.join(' ')
    attrs = {}
    attrs.merge! tag_attrs if tag_attrs.present?
    attrs.merge! build_style(style_attrs) if style_attrs.present?
    attrs.merge! class: class_names
    content_tag 'i', '', attrs
  end
end
