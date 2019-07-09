# Handles the connection to the DB.
class Avram::Connection
  def initialize(@connection_string : String, @database_class : Avram::Database.class)
  end

  def open : DB::Database
    try_connection!
  end

  def try_connection!
    DB.open(@connection_string)
  rescue DB::ConnectionRefused
    raise ConnectionError.new(connection_uri, database_class: @database_class)
  end

  private def connection_uri
    URI.parse(@connection_string)
  end
end
