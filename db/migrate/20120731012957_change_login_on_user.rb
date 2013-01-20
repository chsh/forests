class ChangeLoginOnUser < ActiveRecord::Migration
  def up
    change_column :users, :login, :string, null: false
  end

  def down
    change_column :users, :login, :string, null: true
  end
end
