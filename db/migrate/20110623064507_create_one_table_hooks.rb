class CreateOneTableHooks < ActiveRecord::Migration
  def self.up
    create_table :one_table_hooks do |t|
      t.integer :one_table_id, null: false
      t.string :on, null: false
      t.text :code, null: false
      t.timestamps
    end
    add_index :one_table_hooks, [:one_table_id, :on]
  end

  def self.down
    drop_table :one_table_hooks
  end
end
