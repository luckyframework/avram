# Handles the connection to the DB.
class Avram::Connection
  private getter db : DB::Database? = nil
  private getter credentials : Avram::Credentials

  def initialize(@credentials : Avram::Credentials, @database_class : Avram::Database.class)
  end

  def initialize(connection_string : String, @database_class : Avram::Database.class)
    @credentials = Avram::Credentials.parse(connection_string)
  end

  def open : DB::Database
    @db = try_connection!
  end

  def close : Nil
    @db.try(&.close)
    @db = nil
  end

  def connect_listen(*channels : String, &block : PQ::Notification ->) : Nil
    PG.connect_listen(credentials.url, *channels, &block)
  rescue DB::ConnectionRefused
    raise ConnectionError.new(credentials.uri, database_class: @database_class)
  end

  def try_connection! : DB::Database
    DB.open(credentials.url)
  rescue DB::ConnectionRefused
    raise ConnectionError.new(credentials.uri, database_class: @database_class)
  end
end
