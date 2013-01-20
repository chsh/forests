class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.integer :site_id, :null => false
      t.string :name
      t.text :editable_content, :null => false
      t.text :internal_content
      t.string :path_regexp, :block_keys, :url_keys
      t.boolean :published
      t.string :language
      t.boolean :keyword_logging, default: false
      t.timestamps
    end
  end

  def self.down
    drop_table :pages
  end
end
