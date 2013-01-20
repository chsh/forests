class BlockOneTableHeader < ActiveRecord::Base
  belongs_to :block
  belongs_to :one_table_header

  serialize :options, Hash

  def options
    self[:options] ||= {}
  end
end
