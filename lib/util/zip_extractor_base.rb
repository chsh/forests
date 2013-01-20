require 'unf'

class ZipExtractorBase
  def self.acceptable?(zipfile)
    begin
      validate_args(zipfile)
    rescue
      return false
    end
    true
  end
  def initialize(zipfile, opts = {})
    @opts = opts.reverse_merge! :shallow_path => true
    self.class.validate_args zipfile
    @zipfile = zipfile
  end
  def each_entry(&block)
    raise "Block must be given." unless block_given?
    if @opts[:shallow_path]
      each_entry_with_shallowing(&block)
    else
      each_entry_without_shallowing(&block)
    end
  end
  protected
  def each_entry_with_shallowing(&block)
    paths = collect_paths(zippath)
    @shallower ||= Shallower.new
    new_paths = @shallower.shallow paths
    if new_paths == paths
      each_entry_without_shallowing(&block)
      return
    end
    paths_map = Hash[*[paths, new_paths].transpose.flatten]
    Zip::Archive.open(zippath) do |arc|
      arc.each do |f|
        next if f.directory?
        w = EntryWrapper.new(normalize(paths_map[f.name]), f)
        block.call(w)
      end
    end
  end
  def each_entry_without_shallowing(&block)
    Zip::Archive.open(zippath) do |arc|
      arc.each do |f|
        next if f.directory?
        block.call(f)
      end
    end
  end
  def collect_paths(file)
    paths = []
    Zip::Archive.open(file) do |arc|
      arc.each do |f|
        next if f.directory?
        paths << f.name
      end
    end
    paths
  end
  def self.validate_args(zipfile)
    raise "File not exist." unless File.exist? zipfile
    Zip::Archive.open(zipfile) { |arc| }
  end
  def zippath; raise NotImplementedError.new; end
  private
  def normalize(text)
    normalizer.normalize(text, :nfkc).force_encoding('UTF-8')
  end
  def normalizer
    @normalizer ||= UNF::Normalizer.new
  end
end
