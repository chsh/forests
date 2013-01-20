class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.references :user
      t.string :target_type
      t.integer :target_id
      t.string :action

      t.timestamps
    end
    add_index :activities, :user_id
    add_index :activities, [:target_type, :target_id]
  end
end
