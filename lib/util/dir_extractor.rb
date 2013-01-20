
class DirExtractor
  def initialize(dir)
    validate_args dir
    @dir = dir
  end
  def each_entry(&block)
    raise "Block must be given." unless block_given?
    FileUtils.cd(@dir) do |dir|
      Dir.glob('**/**').sort.each do |entry|
        next if File.directory? entry
        entry.gsub! /^\.\//, ''
        File.open(entry, 'r') do |f|
          block.call(EntryWrapper.new(f.path, f))
        end
      end
    end
  end
  private
  def validate_args(*args)
    dir = args.shift
    raise "Directory does not exist." unless File.directory? dir
  end
end
