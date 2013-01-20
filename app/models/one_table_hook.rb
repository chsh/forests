class OneTableHook < ActiveRecord::Base
  belongs_to :one_table
  def self.on_selections
    @@on_selections ||= [['After Save','after:save']].freeze # currently supported only after save hook.
  end
  def self.on_values
    @@on_values ||= on_selections.map { |it| it[1] }
  end
  validates :on, inclusion: { in: on_values }
  validates :code, presence: true

  def execute(params = {}, optparams = {})
    params[:one_table] ||= self.one_table
    eval self.code
  end
end
