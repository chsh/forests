class UploadedFileOrString
  class BaseObject
    def content_type
      types = MIME::Types.of(self.basename)
      if types.size > 0
        types[0].content_type
      else
        nil
      end
    end
  end
end
class UploadedFileOrString
  class MongoFileObject < BaseObject
    def initialize(mongo_file)
      @mongo_file = mongo_file
      @filepath = @mongo_file.path
      @mongo_files = @mongo_file.mongo_files
    end
    def extname
      File.extname @filepath
    end
    def basename(suffix = nil)
      if suffix
        File.basename @filepath, suffix
      else
        File.basename @filepath
      end
    end
    def size
      mongo_content.size
    end
    def read(*args)
      StringIO.new(mongo_content).read(*args)
    end
    private
    def mongo_content
      @mongo_conent ||= @mongo_files.content(@filepath)
    end
  end
end
class UploadedFileOrString
  class FilepathString < BaseObject
    def initialize(file)
      @filepath = file
      @file = File.new(file)
    end
    def extname
      File.extname @filepath
    end
    def basename(suffix = nil)
      if suffix
        File.basename @filepath, suffix
      else
        File.basename @filepath
      end
    end
    def size
      File.size @filepath
    end
    def read(*args)
      @file.read(*args)
    end
  end
end

class UploadedFileOrString
  class UploadedFile < BaseObject
    def initialize(file)
      @file = file
      @filename = file.original_filename
    end
    def extname
      File.extname @filename
    end
    def basename(suffix = nil)
      if suffix
        File.basename @filename, suffix
      else
        File.basename @filename
      end
    end
    def size
      @file.size
    end
    def read(*args)
      @file.read(*args)
    end
  end
end

class UploadedFileOrString
  def initialize(file)
    @wrapper = detect_file_type(file)
  end
  def read(*args)
    @wrapper.read(*args)
  end
  def method_missing(meth, *args)
    @wrapper.send meth, *args
  end
  private
  def detect_file_type(file)
    if file.is_a?(String) && File.exist?(file)
      FilepathString.new(file)
    elsif file.is_a?(MongoFile)
      MongoFileObject.new(file)
    elsif file.respond_to? :original_filename
      UploadedFile.new(file)
    else
      raise "Unacceptable file type: #{file.class}"
    end
  end
end
