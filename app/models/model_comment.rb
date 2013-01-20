class ModelComment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  serialize :content, Hash

  def content
    self[:content] ||= {}
  end
end
