require 'mongo'

class GridFile

  def initialize(db, namespace = nil)
    @db = db
    @namespace = namespace || Mongo::Grid::DEFAULT_FS_NAME
  end
  def exist?(path)
    files.find({'filename' => path}).next_document != nil
  end
  def open(path, mode = 'r', opts = {}, &block)
    if block_given?
      grid_file_system.open(path, mode, opts) do |gfs|
        block.call(gfs)
      end
    end
  end
  def delete(path)
    grid_file_system.delete(path)
  end
  def destroy
    @db.drop_collection("#{@namespace}.files")
    @db.drop_collection("#{@namespace}.chunks")
  end
  def read(path, writer = nil)
    if writer
      open(path, 'r') do |gs|
        BlockIO.copy(gs, writer)
      end
    else
      open(path, 'r') do |gs|
        gs.read
      end
    end
  end
  def list
    files.find.map { |f| f['filename'] }
  end
  def self.rename(db, name_before, name_after)
    if db.collection_names.include? "#{name_before}.files"
      db.rename_collection("#{name_before}.files", "#{name_after}.files")
    end
    if db.collection_names.include? "#{name_before}.chunks"
      db.rename_collection("#{name_before}.chunks", "#{name_after}.chunks")
    end
  end
  private
  def grid_file_system
    @grid_file_system ||= build_grid_file_system
  end
  def build_grid_file_system
    Mongo::GridFileSystem.new(@db, @namespace)
  end
  def files
    @db.collection("#{@namespace}.files")
  end
end
