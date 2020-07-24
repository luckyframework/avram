class Avram::PostgresURL
  getter database, username, password, hostname, port, query
  property url : String = ""

  def initialize(
    @database : String,
    @hostname : String = "",
    @username : String = "",
    @password : String = "",
    @port : String = "",
    @query : String = ""
  )
  end

  def self.build(**args) : PostgresURL
    new(**args).build
  end

  def self.parse(nothing : Nil)
    nil
  end

  def self.parse(url : String) : PostgresURL
    uri = URI.parse(url)
    build(
      database: uri.path.to_s,
      hostname: uri.host.to_s,
      username: uri.user.to_s,
      password: uri.password.to_s,
      port: uri.port.to_s,
      query: uri.query.to_s
    )
  end

  def build
    sanitize_inputs
    self.url = String.build do |io|
      set_url_protocol(io)
      set_url_creds(io)
      set_url_host(io)
      set_url_port(io)
      set_url_db(io)
    end
    self
  end

  private def sanitize_inputs
    @database = database.strip
    @database = database[1..-1] if database.starts_with?('/')
    if @database.empty?
      raise InvalidDatabaseNameError.new("The database name specified was blank. Be sure to set a value.")
    end
    @hostname = hostname.strip
    @username = username.strip
    @password = password.strip
    @port = port.strip
    @query = query.strip
  end

  private def set_url_db(io)
    io << "/#{database}"
  end

  private def set_url_port(io)
    io << ":#{port}" unless port.empty?
  end

  private def set_url_host(io)
    io << hostname unless hostname.empty?
  end

  private def set_url_creds(io)
    io << URI.encode_www_form(username) unless username.empty?
    io << ":#{URI.encode_www_form(password)}" unless password.empty?
    io << "@" unless username.empty?
  end

  private def set_url_protocol(io)
    io << "postgres://"
  end
end
