class Formula < ActiveRecord::Base
  belongs_to :one_table_header
  serialize :params, Hash
  def eval(row)
    raise NotImplementedError.new
  end
  def new_instance
    self.class.new :params => self.params
  end
end
