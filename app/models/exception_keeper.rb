class ExceptionKeeper < ActiveRecord::Base
  belongs_to :keepable, :polymorphic => true
  serialize :backtrace, Array

  def exception=(e)
    self.class_name = e.class.name
    self.message = e.message
    self.backtrace = e.backtrace
  end
end
