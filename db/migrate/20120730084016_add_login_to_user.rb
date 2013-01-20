class AddLoginToUser < ActiveRecord::Migration
  def change
    add_column :users, :login, :string
    remove_index :users, :email
    change_column :users, :email, :string, null: true
    add_index :users, :login, unique: true
  end
end
