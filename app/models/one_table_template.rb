require 'nkf'
require 'csv'

class OneTableTemplate < ActiveRecord::Base
  belongs_to :one_table
  belongs_to :user # template has owner
  has_many :one_table_template_one_table_headers,
           dependent: :delete_all,
           order: 'display_index'
  has_many :one_table_headers,
           through: :one_table_template_one_table_headers
  has_many :activities, as: :target, order: 'created_at desc'
  serialize :attrs, Hash
  serialize :sort, Array

  scope :by_user, lambda { |user|
    where(user_id: user)
  }

  accepts_nested_attributes_for :one_table_template_one_table_headers

  OUTPUT_FORMATS = [
      [:csv, 1],
      [:tsv, 2]
  ]
  OUTPUT_FORMATS_HASH = Hash[*OUTPUT_FORMATS.flatten.reverse]

  OUTPUT_ENCODINGS = [
      ["Windows ShiftJIS(CP932)", :cp932],
      ["EUC-JP", :euc_jp],
      ["UTF-8", :utf8],
  ]
  OUTPUT_ENCODINGS_HASH = Hash[*OUTPUT_ENCODINGS.flatten.reverse]

  OUTPUT_LFS = [
      [:crlf, 1],
      [:lf, 2],
      [:cr, 3]
  ]
  OUTPUT_LFS_HASH = Hash[*OUTPUT_LFS.flatten.reverse]

  def sort1_key=(value)
    self.sort[0] ||= []
    self.sort[0][0] = value
  end
  def sort1_order=(value)
    self.sort[0] ||= []
    self.sort[0][1] = value
  end
  def sort2_key=(value)
    self.sort[1] ||= []
    self.sort[1][0] = value
  end
  def sort2_order=(value)
    self.sort[1] ||= []
    self.sort[1][1] = value
  end
  def sort3_key=(value)
    self.sort[2] ||= []
    self.sort[2][0] = value
  end
  def sort3_order=(value)
    self.sort[2] ||= []
    self.sort[2][1] = value
  end

  def sort1_key
    self.sort[0] ||= []
    self.sort[0][0]
  end
  def sort1_order
    self.sort[0] ||= []
    self.sort[0][1]
  end
  def sort2_key
    self.sort[1] ||= []
    self.sort[1][0]
  end
  def sort2_order
    self.sort[1] ||= []
    self.sort[1][1]
  end
  def sort3_key
    self.sort[2] ||= []
    self.sort[2][0]
  end
  def sort3_order
    self.sort[2] ||= []
    self.sort[2][1]
  end

  def sort1_key_as_string
    return unless sort1_key.present?
    OneTableHeader.select('label').find(sort1_key).label
  end
  def sort1_order_as_string
    return unless sort1_order.present?
    I18n.t("label_order_#{sort1_order}")
  end
  def sort2_key_as_string
    return unless sort2_key.present?
    OneTableHeader.select('label').find(sort2_key).label
  end
  def sort2_order_as_string
    return unless sort1_order.present?
    I18n.t("label_order_#{sort2_order}")
  end
  def sort3_key_as_string
    return unless sort3_key.present?
    OneTableHeader.select('label').find(sort3_key).label
  end
  def sort3_order_as_string
    return unless sort1_order.present?
    I18n.t("label_order_#{sort3_order}")
  end

  def sort_keys
    @sort_keys ||= build_sort_keys
  end

  def namemap
    os = self.one_table_template_one_table_headers.select { |it|
      it.label.present?
    }
    hl2l = os.map { |it| [it.one_table_header.label, it.label] }
    Hash[*hl2l.flatten]
  end

  def import_uploaded(file)
    nm = self.namemap
    self.one_table.import_uploaded file, namemap: nm
  end

  def output_encoding_as_string
    OUTPUT_ENCODINGS_HASH[self.output_encoding.to_sym]
  end
  def output_format_as_string
    OUTPUT_FORMATS_HASH[self.output_format]
  end
  def output_lf_as_string
    OUTPUT_LFS_HASH[self.output_lf]
  end
  def output_style_as_string
    r = [I18n.t("fileformat.#{output_format_as_string}"), output_encoding_as_string,
         I18n.t("linefeed.#{output_lf_as_string}")].join('/')
    r += "/#{I18n.t(:search)}:#{self.query}" if self.query.present?
    r
  end

  def content_for(opts = {})
    m = "content_for_#{self.output_format_as_string}"
    if respond_to?(m)
      content = self.send(m, opts)
      convert_encoding(convert_lf(content))
    end
  end

  def content_for_csv(opts = {})
    CSV.generate('', {}) do |csv|
      key2idx = {}
      headers = headers_from_one_table_template_one_table_headers
      fields = headers.map { |oth| oth.label || oth.sysname || oth.refname }
      one_table.one_table_headers.each_with_index do |oth, index|
        key2idx[oth.label] = index unless oth.label.blank?
        key2idx[oth.sysname] = index unless oth.sysname.blank?
        key2idx[oth.refname] = index unless oth.refname.blank?
      end
      indexes = fields.map { |key| key2idx[key] }.compact
      unless opts[:no_headers]
        csv << indexes.map { |idx| one_table.one_table_headers[idx].label }
      end
      if self.query.present?
        one_table.find(self.query, rows: one_table.row_size).each do |row|
          csv << indexes.map { |idx| row[idx] }
        end
      else
        one_table.rows.each do |row|
          csv << indexes.map { |idx| row[idx] }
        end
      end
    end
  end

  def content_for_tsv(opts = {})
    CSV.generate('', {col_sep: "\t"}) do |csv|
      key2idx = {}
      headers = headers_from_one_table_template_one_table_headers
      fields = headers.map { |oth| oth.label || oth.sysname || oth.refname }
      one_table.one_table_headers.each_with_index do |oth, index|
        key2idx[oth.label] = index unless oth.label.blank?
        key2idx[oth.sysname] = index unless oth.sysname.blank?
        key2idx[oth.refname] = index unless oth.refname.blank?
      end
      indexes = fields.map { |key| key2idx[key] }.compact
      unless opts[:no_headers]
        csv << indexes.map { |idx| one_table.one_table_headers[idx].label }
      end
      if self.query.present?
        one_table.find(self.query, rows: one_table.row_size).each do |row|
          csv << indexes.map { |idx| row[idx] }
        end
      else
        one_table.rows.each do |row|
          csv << indexes.map { |idx| row[idx] }
        end
      end
    end
  end

  private
  def convert_lf(content)
    case self.output_lf
    when 1 # crlf
      content.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n")
    when 2 # lf
      content.gsub(/\r\n/, "\n")
    when 3 # cr
      content.gsub(/\r\n/, "\n").gsub(/\n/, "\r")
    end
  end
  def convert_encoding(content)
    case self.output_encoding.to_s
    when 'euc_jp'
      NKF.nkf('-We', content)
    when 'cp932'
      NKF.nkf('-Ws', content)
    when 'utf8'
      content
    end
  end
  def build_sort_keys
    self.one_table.one_table_headers.map { |oth|
      [oth.label, oth.id]
    }
  end
  def headers_from_one_table_template_one_table_headers
    headers = self.one_table_template_one_table_headers.
        includes(:one_table_header).select { |h| h.index.present? }.
        map(&:one_table_header)
    return headers unless headers.blank?
    self.one_table_template_one_table_headers.
        includes(:one_table_header).
        map(&:one_table_header)
  end
end
