# -*- encoding: UTF-8 -*-
module PersonalHelper
  def site_title_or_name(site)
    if site.title.blank?
      site.name
    else
      site.title
    end
  end
  def view_by_type(value, opts = {})
    if value.is_a? Hash
      w = value.path('/metadata/width')
      h = value.path('/metadata/height')
      if w && h
        w, h = max_within(w, h, opts[:size_within])
        image_path = "/files/#{opts[:one_table_id]}/#{value.path('/value')}"
        it = image_tag image_path, :width => w, :height => h
        link_to it, image_path, :target => '_blank'
      else
        value
      end
    else
      if opts[:strlen_within]
        charwidth_chop(value, opts[:strlen_within])
      else
        value
      end
    end
  end

  def charwidth(string)
    chars = string.split(//)
    w = 0
    chars.each do |ch|
      w += hf_width(ch)
    end
    w
  end

  def charwidth_chop(value, width)
    return value if value.blank?
    return value unless value.is_a? String
    total_width = 0
    chars = []
    value.split(//).each do |ch|
      hfw = hf_width(ch)
      if (total_width + hfw) > width
        chars << '…'
        break
      end
      total_width += hfw
      chars << ch
    end
    chars.join('')
  end
  def ems_by(rows, opts = {})
    ems = []
    nf = opts[:num_fields] || rows[0].size
    nf.times do |index|
      w = 0
      rows.each do |row|
        rw = charwidth(row[index].to_s)
        w = rw if w < rw
      end
      if w > 40
        w = 40
      end
      ems[index] = w
    end
    ems
  end
  private
  def max_within(width, height, size_within)
    return [width, height] unless size_within
    size_within.to_f
    width = width.to_f; height = height.to_f
    if width < height
      return [width, height] if height <= size_within
      new_height = size_within
      new_width = width / height * size_within
      [new_width.to_i, new_height.to_i]
    else
      return [width, height] if width <= size_within
      new_width = size_within
      new_height = size_within / width * height
      [new_width.to_i, new_height.to_i]
    end
  end
  def hf_width(ch)
    bc = ch.clone.force_encoding("BINARY")
    if bc.length >= 2
      2
    else
      1
    end
  end
end
