
class MongoAttachment < ActiveRecord::Base
  belongs_to :user
#  belongs_to :mongo_connection
  belongs_to :attachable, :polymorphic => true

  after_save :write_file_to_mongo
  def write_file_to_mongo
    unless grid_exist? || file_reader.nil?
      grid_io('w') do |to|
        BlockIO.copy(file_reader, to, Mongo::GridIO::DEFAULT_CHUNK_SIZE)
      end
    end
  end
  def mongo_connection
    MongoConnection.default_gridfs
  end
  def content(&block)
    cb = block_given?
    grid_io do |r|
      if cb
        block.call(r)
      else
        r.read
      end
    end
  end
  def content_size
    grid_attr :file_length
  end
  def content_md5
    grid_attr :get_md5
  end
  def filepath
    self.tempfile.path
  end
  def tempfile
    t = Tempfile.new('mongo_attachment', encoding: 'BINARY')
    grid_io do |r|
      BlockIO.copy(r, t)
    end
    t.close(false)
    t
  end
  def file=(tempfile_or_path)
    if tempfile_or_path.is_a? MongoAttachment
      metadata[:filename] = tempfile_or_path.metadata[:filename]
      metadata[:content_type] = tempfile_or_path.metadata[:content_type]
      metadata[:size] = tempfile_or_path.metadata[:size]
      @reader = StringIO.new(tempfile_or_path.content)
    else
      @reader = UploadedFileOrString.new(tempfile_or_path)
      metadata[:filename] = @reader.basename
      metadata[:content_type] = @reader.content_type
      metadata[:size] = @reader.size
    end
  end
  def metadata
    @metadata ||= {}
  end
  private
  def grid_io(flag = 'r')
    raise "Block must be given." unless block_given?
    GridFile.new(self.mongo_connection.remote_connection).open(self.id.to_s, flag) do |io|
      yield io
    end
  end
  def grid_exist?
    GridFile.new(self.mongo_connection.remote_connection).exist? self.id.to_s
  end

  def grid_attr(key)
    return nil unless grid_exist?
    grid_io do |r|
      r.send key
    end
  end
  def file_reader
    @reader
  end
  def static_file?(target)
    target.is_a?(String) && File.exist?(target)
  end
  def uploaded_file?(target)
    target.respond_to? :original_filename
  end
end
