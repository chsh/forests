class CreateBlockContents < ActiveRecord::Migration
  def self.up
    create_table :block_contents do |t|
      t.integer :block_id, :null => false
      t.string :content_type
      t.text :content
      t.timestamps
    end
    add_index :block_contents, [:block_id, :content_type], :unique => true
  end

  def self.down
    drop_table :block_contents
  end
end
