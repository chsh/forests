

class SerialValue
  def initialize
    @@connection ||= ActiveRecord::Base.connection
    begin
      @value = next_value
    rescue ActiveRecord::StatementInvalid
      create_sequence
      @value = next_value
    end
  end
  def value; @value; end
  def v; value; end

  def to_i; @value; end
  def to_s; @value.to_s; end

  private
  SEQ_NAME = 'serial_provider_seq'
  def next_value
    r = @@connection.send :select, "select nextval('#{SEQ_NAME}')"
    r[0]['nextval'].to_i
  end
  def create_sequence
    @@connection.execute("create sequence #{SEQ_NAME}")
  end
end
