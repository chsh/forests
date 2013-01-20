class RemoveConnectionIdFromAny < ActiveRecord::Migration
  def up
    remove_column :one_tables, :mongo_connection_id
    remove_column :mongo_attachments, :mongo_connection_id
    remove_column :one_tables, :solr_connection_id
    remove_column :one_tables, :media_keeper_id
  end

  def down
    raise "This migration never be undone."
  end
end
