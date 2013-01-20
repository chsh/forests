class CreateOneTableTemplates < ActiveRecord::Migration
  def change
    create_table :one_table_templates do |t|
      t.references :one_table
      t.references :user
      t.string :name
      t.integer :output_format
      t.string :output_encoding
      t.integer :output_lf
      t.text :attrs
      t.string :query
      t.string :sort

      t.timestamps
    end
    add_index :one_table_templates, :one_table_id
    add_index :one_table_templates, :user_id
  end
end
