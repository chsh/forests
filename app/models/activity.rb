class Activity < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, polymorphic: true
  belongs_to :one_table
  attr_accessible :action, :target

  scope :recently_created, order('created_at desc')

  before_create do
    if self.target.present?
      if self.target.respond_to?(:one_table_id)
        self.one_table_id = self.target.one_table_id
      elsif self.target.is_a? OneTable
        self.one_table_id = self.target.id
      end
    end
  end
end
