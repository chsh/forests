
class MagickCommand

  def self.unique_transaction_id
    @@magick_id = (@@magick_id ||= 0) + 1
    "MagickCommand-#{@@magick_id}-#{SecureRandom.hex(64)}"
  end
  class Identify
    def initialize(path)
      @path = path
    end
    def size(path_or_content, opts = {})
      path(path_or_content) do |filepath|
        result = `#{@path} '#{filepath.gsub("'", "\\'")}'`
        # result shows 'fullpath format WxH etc...
        raw = result.split(/\s+/)[2]
        return raw if opts[:result] == :string
        wh = raw.split(/x/)
        { :width => wh[0].to_i, :height => wh[1].to_i }
      end
    end
    private
    def path(file_or_content)
      raise "Block must be given." unless block_given?
      if !file_or_content.index("\0") && File.exist?(file_or_content)
        yield(file_or_content)
      else
        # create and pass tempfile
        tf = Tempfile.new(MagickCommand.unique_transaction_id, encoding: 'BINARY')
        begin
          tf.write(file_or_content)
          tf.close
          yield(tf.path)
        ensure
          tf.close(true)
        end
      end
    end
  end

  def self.size(path_or_content, opts = {})
    identify.size(path_or_content, opts)
  end

  private
  def self.identify
    @@identify_path ||= Identify.new(build_identify_path)
  end
  def self.build_identify_path
    pick_path_for('identify') || raise("ImageMagick convert command not found.")
  end
  def self.pick_path_for(cmd_name)
    path = class_config["#{cmd_name}_path"]
    return path if !path.blank? && File.exist?(path)
    path = `which #{cmd_name}`.strip
    return path if !path.blank? && File.exist?(path)
  end
end
