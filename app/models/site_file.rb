class SiteFile < ActiveRecord::Base
  belongs_to :site

  before_destroy :delete_file_path
  def delete_file_path
    site.files.delete path
  end

  before_save :save_file
  def save_file
    if @file
      site.files.save path, @file.read
    elsif @text_content
      site.files.save path, @text_content
    end
  end
  after_save :invalidate_cache
  def invalidate_cache
    RawMemCache.invalidate! "/#{site.name}/#{self.path}"
  end

  def file=(value)
    if value.is_a? String
      raise "File doesn't exist.:#{value}" unless File.exist?(value)
      value = File.new(value)
    end
    @file = value
  end

  def text_content=(value)
    @text_content = value
  end
  def text_content
    @text_content ||= site.files.load path if path && text?
  end

  def text?
    return nil unless path
    path =~ /\.(js|html?|css|xml|text|txt)$/ ? true : false
  end

end
