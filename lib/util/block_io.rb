
class BlockIO
  def self.copy(from, to, chunk_size = 1024*64)
    loop do
      buf = from.read(chunk_size)
      break if buf.blank?
      to.write buf
    end
  end
end
