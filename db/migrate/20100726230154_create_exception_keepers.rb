class CreateExceptionKeepers < ActiveRecord::Migration
  def self.up
    create_table :exception_keepers do |t|
      t.string :keepable_type, :null => false
      t.integer :keepable_id, :null => false

      t.string :class_name, :null => false
      t.text :message, :null => false
      t.text :backtrace, :null => false

      t.timestamps
    end
    add_index :exception_keepers, [:keepable_type, :keepable_id]
  end

  def self.down
    drop_table :exception_keepers
  end
end
