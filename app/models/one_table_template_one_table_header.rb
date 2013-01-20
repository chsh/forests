class OneTableTemplateOneTableHeader < ActiveRecord::Base
  belongs_to :one_table_template
  belongs_to :one_table_header

end
