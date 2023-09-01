# Handles the connection to the DB.
class Avram::Connection
  private getter db : DB::Database? = nil

  def initialize(@connection_string : String, @database_class : Avram::Database.class)
  end

  def open : DB::Database
    @db = try_connection!
  end

  def close : Nil
    @db.try(&.close)
    @db = nil
  end

  def connect_listen(*channels : String, &block : PQ::Notification ->) : Nil
    PG.connect_listen(@connection_string, *channels, &block)
  rescue DB::ConnectionRefused
    raise ConnectionError.new(connection_uri, database_class: @database_class)
  end

  def try_connection! : DB::Database
    DB.open(@connection_string)
  rescue DB::ConnectionRefused
    raise ConnectionError.new(connection_uri, database_class: @database_class)
  end

  private def connection_uri : URI
    URI.parse(@connection_string)
  end
end
