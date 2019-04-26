# Handles the connection to the DB.
class Avram::Connection
  def self.open(connection_string : String) : DB::Database
    conn = self.new(connection_string)
    conn.try_connection!
  end

  def initialize(@connection_string : String)
  end

  def try_connection!
    DB.open(@connection_string)
  rescue DB::ConnectionRefused
    raise ConnectionError.new(connection_uri)
  end

  private def connection_uri
    URI.parse(@connection_string)
  end
end
