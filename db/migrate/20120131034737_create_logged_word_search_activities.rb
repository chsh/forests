class CreateLoggedWordSearchActivities < ActiveRecord::Migration
  def self.up
    create_table :logged_word_search_activities do |t|
      t.integer :logged_word_id
      t.integer :search_activity_id
      t.datetime :stamped_at
    end
    add_index :logged_word_search_activities, [:logged_word_id, :search_activity_id, :stamped_at],
              name: 'index_lwsa_on_lw_and_sa_and_s'
  end

  def self.down
    drop_table :logged_word_search_activities
  end
end
