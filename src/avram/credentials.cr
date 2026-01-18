require "uri"

class Avram::Credentials
  getter uri : URI

  def initialize(
    database : String,
    scheme : String = "postgres",
    hostname : String? = nil,
    username : String? = nil,
    password : String? = nil,
    port : Int32? = nil,
    query : String? = nil,
  )
    # NOTE: We need the empty string on `host` to support Unix socket style connection.
    # without that (and the front slash on `path`), URI returns "postgres:test_db"
    @uri = URI.new(
      scheme: scheme.strip,
      host: hostname.try(&.strip).presence || "",
      port: port,
      path: database.starts_with?('/') ? database.strip : "/#{database.strip}",
      query: query.try(&.strip).presence,
      user: username.try(&.strip).presence,
      password: password.try(&.strip).presence
    )
  end

  def initialize(@uri : URI)
  end

  # Used when you need to configure credentials,
  # but no database connection is made.
  def self.void : Credentials
    new(database: "unused")
  end

  # Parse a DB connection string URL. This may come from an
  # environment variable.
  # Returns `nil` if no `connection_url` is provided.
  #
  # ```
  # Avram::Credentials.parse?(ENV["DB_URL"]?)
  # ```
  def self.parse?(connection_url : String?) : Credentials?
    return nil if connection_url.nil?
    parse(connection_url.as(String))
  end

  # Parse a DB connection string URL. This may come from an
  # environment variable.
  #
  # ```
  # Avram::Credentials.parse(ENV["DB_URL"])
  # ```
  def self.parse(connection_url : String) : Credentials
    uri = URI.parse(connection_url)
    instance = new(uri)
    instance.database
    instance
  end

  # This is the full URL including the database, querystring, etc...
  # e.g. postgres://user:pass@host:1234/db?a=1
  def url : String
    uri.to_s
  end

  def protocol : String
    "#{uri.scheme}://"
  end

  # The name of the database you want to connect to
  def database : String
    # delete the front slash if it exists
    uri.path.presence.try(&.delete('/')) || raise InvalidDatabaseNameError.new("The database name specified was blank. Be sure to set a value.")
  end

  def hostname : String?
    uri.host
  end

  def username : String?
    uri.user
  end

  def password : String?
    uri.password
  end

  def port : Int32?
    uri.port
  end

  def query : String?
    uri.query
  end

  # This is the connection string without the DB, or query added in.
  # This is used for connecting to the database engine without connecting to a specific
  # database.
  # e.g. postgres://user:pass@host:1234
  def connection_string : String
    uri.to_s.gsub(uri.request_target, "").chomp('/')
  end

  # Returns the connection string without
  # any query params.
  def url_without_query_params : String
    uri.to_s.gsub("?#{uri.query}", "")
  end
end
