class CreateModelComments < ActiveRecord::Migration
  def self.up
    create_table :model_comments do |t|
      t.string :commentable_type, :null => false
      t.integer :commentable_id, :null => false
      t.text :content
      t.timestamps
    end
    add_index :model_comments, [:commentable_type, :commentable_id]
  end

  def self.down
    drop_table :model_comments
  end
end
