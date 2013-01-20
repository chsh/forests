class MongoFile
  def initialize(mongo_files, path)
    @mongo_files = mongo_files
    @path = path
  end
  attr_reader :mongo_files, :path
end
