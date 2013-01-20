require 'mongo'


class MongoStore < KVStore::Base
  def get(key)
    (@con.find_one('_id' => key) || {})['v']
  end
  def put(key, value)
    @con.save '_id' => key, 'v' => value
  end
  def delete_within_block(key)
    @con.remove '_id' => key
  end
  def connection_with_context(context)
    con = Mongo::Connection.new host, port
    con.db(database).create_collection(context)
  end
  def close
    return unless @con
    @con.db.connection.close
    @con = nil
  end
  private
  def host; cc[:host]; end
  def port; cc[:port]; end
  def database; cc[:database]; end
  def cc
    @@cc ||= build_cc
  end
  def build_cc
    ccc = self.class.class_config
    host = ccc.host || 'localhost'
    port = ccc.port || 27017
    { :host => host, :port => port.to_i, :database => ccc['database'] }
  end
end
