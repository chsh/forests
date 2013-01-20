class CreateOwnerUsers < ActiveRecord::Migration
  def self.up
    create_table :owner_users do |t|
      t.integer :owner_id, :user_id, :null => false
      t.timestamps
    end
    add_index :owner_users, :owner_id
    add_index :owner_users, :user_id
  end

  def self.down
    drop_table :owner_users
  end
end
