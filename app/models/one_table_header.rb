# encoding: UTF-8
class OneTableHeader < ActiveRecord::Base
  SYM2KIND_MAP = {
    :string => 1,
    :text => 2,
    :time => 3,
    :integer => 4,
    :include_string => 5,
    :image => 6,
  }
  KIND2SYM_MAP = {
    1 => :string,
    2 => :text,
    3 => :time,
    4 => :integer,
    5 => :include_string,
    6 => :image,
  }
  KIND2QSUF_MAP = {
    1 => 's',
    2 => 't',
    3 => 'd',
    4 => 'i',
    5 => 's',
    6 => nil, # do not save as solr record wo/ metadata.
  }

  KIND_STRING = 1
  KIND_TEXT= 2
  KIND_DATE = 3
  KIND_INTEGER = 4
  KIND_INCLUDE_STRING = 5
  KIND_IMAGE = 6

  KIND_LABELS = [
      ['コード(固定文字列)', 1],
      ['テキスト', 2],
      ['日付', 3],
      ['数字', 4],
      ['固定文字列(include)', 5],
      ['画像', 6],
  ]

  KIND_TO_STRING_MAP = {
      1 => 'String',
      2 => 'Text',
      3 => 'Date',
      4 => 'Integer',
      5 => 'IncludeString',
      6 => 'Image',
  }

  FILE_FIELD_MAP = {
      6 => true
  }

  belongs_to :one_table
  has_many :block_one_table_headers, :dependent => :delete_all
  has_one :model_comment, :as => :commentable, :dependent => :delete
  has_one :formula, :dependent => :delete

  accepts_nested_attributes_for :model_comment

  scope :primary_key_present, where(primary_key: true)

  def metadata_json
    self.metadata.to_json
  end
  def metadata_json=(json)
    begin
      hash = JSON.parse(json)
      self.model_comment ||= ModelComment.new
      self.model_comment.content = hash
    rescue
    end
  end
  def metadata
    mc = (self.model_comment ||= ModelComment.new)
    mc.content
  end
  def update_metadata(hash)
    self.model_comment ||= ModelComment.new
    self.model_comment.content ||= {}
    self.model_comment.content.merge! hash
    self.model_comment.save
  end

  def file_field?
    FILE_FIELD_MAP[self[:kind]] ? true : false
  end
  def kind_as_string
    KIND_TO_STRING_MAP[self[:kind]]
  end
  def self.find_virtual_headers(ids = nil)
    if ids
      ids = [ids].flatten.sort.uniq
      oths = self.find(:all, :conditions => { :id => ids })
    else
      oths = self.find(:all)
    end
    oths.map { |oth| oth.formula ? oth : nil }.compact
  end
  def new_instance
    oth = OneTableHeader.new self.attributes
    oth.formula = self.formula.new_instance if self.formula
    oth
  end

  def comment(refresh = false)
    @comment = nil if refresh
    @comment ||= (self.model_comment || ModelComment.new).content
  end
  def comment=(value)
    @comment = value
  end
  after_save :save_model_comment
  def save_model_comment
    if @comment
      mc = self.model_comment || self.create_model_comment
      mc.update_attributes :content => @comment
    end
  end

  attr_accessor :display_index, :input_type, :user_list

  def suffix(default = 't')
    KIND2QSUF_MAP[self.kind] || default
  end

  def self.name_to_label(value)
    self.find_by_name(value, :select => 'label').label
  end

  def solr_key_and_value_pairs(*args)
    if self.multiple?
      solr_key_and_multiple_value_pairs(args.flatten)
    else
      raise "Argument error." unless args.size == 1
      solr_key_and_single_value_pairs(args[0])
    end
  end

  def key_and_value(*args)
    [self.sysname, solr_value(*args)]
  end

  def solr_key
    "#{self.sysname}_#{self.suffix}#{mc}"
  end
  def solr_xattr_key(name, type)
    "#{self.sysname}_#{name}_#{type}"
  end

  def solr_value(*args)
    if self.multiple?
      solr_multiple_value(args.flatten)
    else
      solr_single_value(args[0])
    end
  end

  def selected
    self.display_index.blank? ? false : true
  end

  private
  def solr_multiple_value(values)
    values.map { |value| solr_single_value(value) }
  end
  def solr_single_value(value)
    if self.kind == 3
      value.to_time if value
    else
      value
    end
  end
  def mc
    self.multiple? ? 'm' : ''
  end

  def solr_key_and_multiple_value_pairs(values)
    if values.size > 0
      if self.kind == 3
        svs = solr_value(values)
        lts = svs.map(&:getlocal)
        [solr_key, svs,
         solr_xattr_key(:wday, :im), lts.map(&:wday),
         solr_xattr_key(:year, :im), lts.map(&:year),
         solr_xattr_key(:month, :im), lts.map(&:month),
         solr_xattr_key(:day, :im), lts.map(&:day)
        ]
      else
        [solr_key, solr_multiple_value(values)]
      end
    else
      []
    end
  end
  def solr_key_and_single_value_pairs(value)
    if value
      if self.kind == KIND_DATE
        sv = solr_value(value)
        lt = sv.getlocal
        [solr_key, sv.utc.iso8601,
         solr_xattr_key(:wday, :i), lt.wday,
         solr_xattr_key(:year, :i), lt.year,
         solr_xattr_key(:month, :i), lt.month,
         solr_xattr_key(:day, :i), lt.day
        ]
      elsif self.kind == KIND_IMAGE
        # image field has only attribute values.
        [solr_xattr_key(:width, :i), value.path('/metadata/width'),
         solr_xattr_key(:height, :i), value.path('/metadata/height')]
      else
        [solr_key, solr_single_value(value)]
      end
    else
      []
    end
  end
end
