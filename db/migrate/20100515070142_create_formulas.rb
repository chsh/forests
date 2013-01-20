class CreateFormulas < ActiveRecord::Migration
  def self.up
    create_table :formulas do |t|
      t.integer :one_table_header_id, :null => false
      t.string :type
      t.text :params
      t.timestamps
    end
  end

  def self.down
    drop_table :formulas
  end
end
