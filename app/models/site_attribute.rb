require 'digest/sha1'

class SiteAttribute < ActiveRecord::Base
  belongs_to :site

  attr_accessor :file

  has_one :admin_option, :as => :attachable, :dependent => :delete

  serialize :metadata, Hash

  validates_presence_of :site_id

  before_save :fill_empty_fields
  def fill_empty_fields
    self.metadata
    if file
      if !self.value.blank? && self.site.files.exist?(self.value)
        self.site.files.delete self.value
      end
      ufs = UploadedFileOrString.new(file)
      randpath = nil
      loop do
        randpath = "files/#{SecureRandom.hex(20)}#{ufs.extname}"
        break unless self.site.files.exist?(randpath)
      end
      self.site.files.save randpath, ufs
      self.value = randpath
      setup_metadata_for_image randpath
    end
    (self.admin_option ||= self.build_admin_option).save
  end
  after_destroy :delete_files_if_exist
  def delete_files_if_exist
    if file?
      self.site.files.delete self.value
    end
  end
  def attributes_for_new_instance
    if file?
      {
              'file' => MongoFile.new(self.site.files, self.value),
              'key' => self.key,
              'value' => self.value,
              'metadata' => self.metadata
      }
    else
      self.attributes
    end
  end
  def file?
    self.site.files.exist? self.value
  end
  def value_as_html
    return nil unless self.value
    if value =~ /^files\//
      sz = self.metadata['image_size']
      if sz
        "<img src=\"/#{self.site.name}/#{value}\"/>"
      end
    else
      self.value
    end
  end
  def admin_options
    (self.admin_option ||= self.build_admin_option).attrs
  end

  def description=(value)
    @description = admin_options[:description] = value
  end
  def description
    @description ||= admin_options[:description]
  end
  def metadata
    self[:metadata] ||= {}
  end
  def protected_key=(value)
    metadata['protected_key'] = value ? true : false
  end
  def protected_key
    metadata['protected_key'] = false if metadata['protected_key'].nil?
    metadata['protected_key']
  end
  def protected_key?; protected_key; end
  def image?
    metadata['image_size'] ? true : false
  end
  def image_size
    @image_size ||= ImageSize.new metadata['image_size']
  end

  def render_content(path_hint)
    return value unless file?
    # 'image/size/test.html' -> '../../files/___.png'
    # 'test.html' -> 'files/___.png'
    new_path = '../' * (path_hint.split('/').size - 1) + value
    if image?
      "<img src='#{new_path}' width='#{image_size.width}' height='#{image_size.height}'/>"
    else
      new_path
    end
  end

  private
  def setup_metadata_for_image(path)
    tps = MIME::Types.of(path)
    if tps.size > 0 && tps[0].media_type == 'image'
      wh = MagickCommand.size(self.site.files.content(path), :result => :string)
      metadata['image_size'] = wh
    end
  end
  class ImageSize
    def initialize(image_size_str)
      if image_size_str =~ /^(\d+)x(\d+)$/
        @width = $1.to_i; @height = $2.to_i
      else
        @width = nil; @height = nil
      end
    end
    attr_reader :width, :height
  end
end
