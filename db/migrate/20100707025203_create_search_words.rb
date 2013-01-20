class CreateSearchWords < ActiveRecord::Migration
  def self.up
    create_table :search_words do |t|
      t.integer :search_word_list_id
      t.integer :index
      t.string :display_value
      t.string :search_value

      t.timestamps
    end
    add_index :search_words, [:search_word_list_id, :index], :unique => true
  end

  def self.down
    drop_table :search_words
  end
end
