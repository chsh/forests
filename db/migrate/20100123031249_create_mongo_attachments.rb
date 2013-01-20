class CreateMongoAttachments < ActiveRecord::Migration
  def self.up
    create_table :mongo_attachments do |t|
      t.integer :user_id, :mongo_connection_id, :null => false
      t.integer :attachable_id
      t.string :attachable_type
      t.string :filename, :content_type
      t.integer :size
      t.timestamps
    end
    add_index :mongo_attachments, :user_id
    add_index :mongo_attachments, :mongo_connection_id
    add_index :mongo_attachments,
              [:attachable_type, :attachable_id, :filename],
              :unique => true,
              :name => 'index_mas_attachable_type_id_and_filename'
  end

  def self.down
    drop_table :mongo_attachments
  end
end
