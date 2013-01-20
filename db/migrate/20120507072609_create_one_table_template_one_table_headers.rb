class CreateOneTableTemplateOneTableHeaders < ActiveRecord::Migration
  def change
    create_table :one_table_template_one_table_headers do |t|
      t.references :one_table_template
      t.references :one_table_header
      t.boolean :used, default: false
      t.integer :index
      t.string :query
      t.string :label
      t.timestamps
    end
    add_index :one_table_template_one_table_headers,
              [ :one_table_template_id, :one_table_header_id ],
              name: 'index_ottoth_on_ott_and_oth',
              unique: true
    add_index :one_table_template_one_table_headers,
              [ :one_table_template_id, :index ],
              name: 'index_ottoth_on_ott_and_index'
  end
end
