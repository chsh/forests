class AddOneTableIdToActivity < ActiveRecord::Migration
  def change
    add_column :activities, :one_table_id, :integer
    add_index :activities, :one_table_id
    Activity.all.each do |activity|
      if activity.target.respond_to? :one_table
        activity.one_table = activity.target.one_table
        activity.save
      end
    end
  end
end
