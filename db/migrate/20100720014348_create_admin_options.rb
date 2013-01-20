class CreateAdminOptions < ActiveRecord::Migration
  def self.up
    create_table :admin_options do |t|
      t.string :attachable_type
      t.integer :attachable_id
      t.text :attrs
      t.timestamps
    end
    add_index :admin_options, [:attachable_type, :attachable_id]
  end

  def self.down
    drop_table :admin_options
  end
end
