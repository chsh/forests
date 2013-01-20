class AddIsPublicToOneTable < ActiveRecord::Migration
  def change
    add_column :one_tables,:is_public, :boolean, default: true
    add_index :one_tables, :is_public
    OneTable.all.each do |ot|
      ot.update_attributes is_public: true
    end
  end
end
