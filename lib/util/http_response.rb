class HttpResponse
  attr_reader :status, :headers
  def initialize(status, headers, *contents)
    @status = status
    @headers = headers
    @contents = [contents].flatten
  end

  def ok?
    @status == 200
  end
  def not_found?
    @status == 404
  end
  def redirect?
    @status == 301
  end

  def content
    @contents.join('')
  end

  def to_metal_response
    @metal_response ||= [@status, @headers, @contents]
  end

  def self.not_found
    @@not_found ||= HttpResponse.new(404, {"Content-Type" => "text/html"}, "Not Found")
  end

  def self.ok(headers, *contents)
    new(200, headers, *contents)
  end
end
