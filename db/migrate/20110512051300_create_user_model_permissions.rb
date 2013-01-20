class CreateUserModelPermissions < ActiveRecord::Migration
  def self.up
    create_table :user_model_permissions do |t|
      t.integer :user_id, null: false
      t.string :model_type, null: false
      t.integer :model_id # when nil, points model_type only.
      t.integer :flags
      t.timestamps
    end
    add_index :user_model_permissions, :user_id
    add_index :user_model_permissions, [:model_type, :model_id]
    add_index :user_model_permissions, :flags
  end

  def self.down
    drop_table :user_model_permissions
  end

end
