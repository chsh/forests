class CreateSearchActivities < ActiveRecord::Migration
  def self.up
    create_table :search_activities do |t|
      t.integer :site_id, null: false
      t.datetime :stamped_at, null: false
    end
    add_index :search_activities, [:site_id, :stamped_at]
  end

  def self.down
    drop_table :search_activities
  end
end
