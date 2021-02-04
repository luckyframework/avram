class Avram::Credentials
  getter url : String

  def initialize(
    @database : String,
    @hostname : String? = nil,
    @username : String? = nil,
    @password : String? = nil,
    @port : Int32? = nil,
    @query : String? = nil
  )
    @url = build_url
  end

  # Used when you need to configure credentials,
  # but no database connection is made.
  def self.void : Credentials
    new(database: "unused")
  end

  # Parse a postgres connection string URL. This may come from an
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

  # Parse a postgres connection string URL. This may come from an
  # environment variable.
  #
  # ```
  # Avram::Credentials.parse(ENV["DB_URL"])
  # ```
  def self.parse(connection_url : String) : Credentials
    uri = URI.parse(connection_url)
    new(
      database: uri.path.to_s,
      hostname: uri.host,
      username: uri.user,
      password: uri.password,
      port: uri.port,
      query: uri.query
    )
  end

  # The name of the database you want to connect to
  def database : String
    @database = @database.strip
    @database = @database[1..-1] if @database.starts_with?('/')

    if @database.empty?
      raise InvalidDatabaseNameError.new("The database name specified was blank. Be sure to set a value.")
    end

    @database
  end

  def hostname : String?
    @hostname.try(&.strip).presence
  end

  def username : String?
    @username.try(&.strip).presence
  end

  def password : String?
    @password.try(&.strip).presence
  end

  def port : Int32?
    @port
  end

  def query : String?
    @query.try(&.strip).presence
  end

  # Returns the postgres connection string without
  # any query params.
  def url_without_query_params : String
    url.sub("?#{@query}", "")
  end

  private def build_url
    String.build do |io|
      set_url_protocol(io)
      set_url_creds(io)
      set_url_host(io)
      set_url_port(io)
      set_url_db(io)
      set_url_query(io)
    end
  end

  private def set_url_db(io)
    io << "/#{database}"
  end

  private def set_url_port(io)
    port.try do |the_port|
      io << ":#{the_port}"
    end
  end

  private def set_url_host(io)
    hostname.try do |host|
      io << host
    end
  end

  private def set_url_creds(io)
    set_at = false
    username.try do |user|
      io << URI.encode_www_form(user)
      set_at = true
    end

    password.try do |pass|
      io << ":#{URI.encode_www_form(pass)}"
      set_at = true
    end

    io << "@" if set_at
  end

  private def set_url_protocol(io)
    io << "postgres://"
  end

  private def set_url_query(io)
    query.try do |q|
      io << "?#{q}"
    end
  end
end
