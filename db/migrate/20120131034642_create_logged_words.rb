class CreateLoggedWords < ActiveRecord::Migration
  def self.up
    create_table :logged_words do |t|
      t.integer :site_id, null: false
      t.string :value, null: false
      t.integer :logged_word_search_activities_count, default: 0
      t.timestamps
    end
    add_index :logged_words, [:site_id, :value], unique: true
    add_index :logged_words, [:site_id, :logged_word_search_activities_count],
      name: 'index_logged_words_on_site_and_lwsac'
  end

  def self.down
    drop_table :logged_words
  end
end
