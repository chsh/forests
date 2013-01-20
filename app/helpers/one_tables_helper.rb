# -*- encoding: UTF-8 -*-
module OneTablesHelper
  def hilite_query(value, opts = {})
    return value if value.blank?
    value = value.join(', ') if value.is_a?(Array)
    value = value.to_s
    if opts[:limit]
      value = value[0, opts[:limit]]
    end
    return value unless opts[:query]
    qs = opts[:query].strip.split(/[\s　]+/).sort { |a, b|
      b.length <=> a.length
    }
    qs.each do |q|
      value.gsub!(q, "<span style=\"background-color: yellow\"><em>#{q}</em></span>")
    end
    value
  end
end
