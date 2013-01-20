
require 'zip_extractor'

class MongoFilesExtractor
  def initialize(mongo_files)
    @mongo_files = mongo_files
  end
  def each_entry(&block)
    raise "Block must be given." unless block_given?
    @mongo_files.list_names.each do |name|
      io = StringIO.new @mongo_files.content(name)
      block.call(EntryWrapper.new(name, io))
    end
  end
end
class MongoFiles
  attr_reader :name, :opts
  def initialize(name, opts = {})
    @name = name
    @opts = opts
    regulate_opts(@opts)
  end
  def import(dir_or_zip_or_mongofiles, opts = {})
    if dir_or_zip_or_mongofiles.is_a? MongoFiles
      extractor = MongoFilesExtractor.new(dir_or_zip_or_mongofiles)
    elsif ZipExtractor.acceptable?(dir_or_zip_or_mongofiles)
      extractor = ZipExtractor.from(dir_or_zip_or_mongofiles, opts)
    elsif File.directory?(dir_or_zip_or_mongofiles)
      extractor = DirExtractor.new(dir_or_zip_or_mongofiles)
    else raise "Unexpected import file type:#{dir_or_zip_or_mongofiles.class}"
    end
    dbc = db
    extractor.each_entry do |entry|
      next if excluded_pattern?(entry)
      save_to(dbc, entry)
    end
  end

  def destroy
    GridFile.new(db, @name).destroy
  end

  def list_names
    GridFile.new(db, @name).list
  end

  def self.rename(name_before, name_after)
    GridFile.rename(MongoConnection.site_filesystem.remote_connection, name_before, name_after)
  end

  def delete(*paths)
    gf = GridFile.new(db, @name)
    [paths].flatten.each do |path|
      gf.delete path
    end
  end

  def add(*paths)
    paths = [paths].flatten
    paths.each do |path|
      raise "File not found.(#{path})" unless File.exist? path
    end
    paths.each do |path|
      save path, File.open(path, 'rb').read
    end
  end

  def save(path, content_or_reader)
    if content_or_reader.respond_to? :read
      entry = EntryWrapper.new(path, content_or_reader)
    else
      entry = EntryWrapper.new(path, StringIO.new(content_or_reader))
    end
    save_to(db, entry)
  end

  def exist?(path)
    GridFile.new(db, @name).exist? path
  end
  def content(path)
    load_from(db, path)
  end
  def load(path); content(path); end
  private
  def db
    (@db || MongoConnection.site_filesystem).remote_connection
  end
  def save_to(db, entry)
    opts = {
            :content_type => content_type_from(entry.name)
    }

    GridFile.new(db, @name).open(entry.name, 'w', opts) do |gs|
      c = (entry.read || ''.force_encoding('BINARY'))
      gs.write c
    end
  end
  def load_from(db, name)
    GridFile.new(db, @name).open(name, 'r') do |gs|
      gs.read
    end
  end
  def content_type_from(filename)
    content_type = 'text/plain'
    mts = MIME::Types.of(filename)
    if mts && mts.size > 0
      content_type = mts[0].content_type
    end
    content_type
  end
  def excluded_pattern?(entry)
    return false unless @opts[:exclude_patterns]
    @opts[:exclude_patterns].each do |pat|
      return true if entry.name =~ pat
    end
    false
  end
  def regulate_opts(opts)
    opts[:exclude_patterns] = [opts[:exclude_patterns]].flatten if opts[:exclude_patterns]
    @db = opts[:db] if opts[:db]
  end
end
