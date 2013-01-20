class CreateSearchWordLists < ActiveRecord::Migration
  def self.up
    create_table :search_word_lists do |t|
      t.integer :user_id
      t.string :name

      t.timestamps
    end
    add_index :search_word_lists, [:user_id, :name], :unique => true
  end

  def self.down
    drop_table :search_word_lists
  end
end
