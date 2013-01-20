class AddDisplayIndexToOneTableTemplateOneTableHeader < ActiveRecord::Migration
  def change
    add_column :one_table_template_one_table_headers, :display_index, :integer
    add_index :one_table_template_one_table_headers, :display_index
    OneTableTemplate.all.each do |ott|
      id2ottoth = ott.one_table_template_one_table_headers.index_by(&:one_table_header_id)
      ott.one_table_headers.each_with_index do |oth, index|
        ottoth = id2ottoth[oth.id]
        ottoth.display_index = index
        ottoth.save
      end
    end
  end
end
