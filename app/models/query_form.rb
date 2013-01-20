class QueryForm
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_accessor :q
  def persisted?; false end

  def initialize(params = {})
    params.each do |key, value|
      alter_method = "#{key}="
      self.send(alter_method, value) if self.respond_to? alter_method
    end
  end
end
