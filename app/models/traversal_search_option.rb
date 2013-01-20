class TraversalSearchOption < ActiveRecord::Base
  belongs_to :one_table
  before_save :fill_empty_values
  serialize :options, Hash

  def options
    self[:options] ||= {}
  end
  def fields_map
    options[:fields_map] ||= {}
  end
  def fields_map=(value)
    options[:fields_map] = value
  end
  def url_format
    options[:url_format] ||= {}
  end
  def url_format=(value)
    options[:url_format] = value
  end
  private
  def fill_empty_values
    self.fields_map
    self.url_format
  end
end
