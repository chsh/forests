class ZipExtractor
  def self.from(zipfile, opts = {})
    if acceptable? zipfile
      zipfile = zipfile.path if zipfile.respond_to?(:path)
      ZipFileExtractor.new zipfile, opts
    else raise "Unexpected zipfile type:#{zipfile.class}"
    end
  end
  def self.acceptable?(zipfile)
    zipfile = zipfile.path if zipfile.respond_to?(:path)
    ZipFileExtractor.acceptable? zipfile
  end
end
