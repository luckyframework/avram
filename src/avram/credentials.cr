class Avram::Credentials
  getter database, username, password, hostname, port, query
  getter url : String = ""

  def initialize(
    @database : String,
    @hostname : String = "",
    @username : String = "",
    @password : String = "",
    @port : String = "",
    @query : String = ""
  )
  end

  def self.void : Credentials
    build(database: "unused")
  end

  def self.build(**args) : Credentials
    new(**args).build
  end

  def self.parse(nothing : Nil)
    nil
  end

  def self.parse(url : String) : Credentials
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
    @url = String.build do |io|
      set_url_protocol(io)
      set_url_creds(io)
      set_url_host(io)
      set_url_port(io)
      set_url_db(io)
      set_url_query(io)
    end
    self
  end

  def url_without_query_params
    @url.sub("?#{@query}", "")
  end

  private def set_url_db(io)
    @database = database.strip
    if @database.empty?
      raise InvalidDatabaseNameError.new("The database name specified was blank. Be sure to set a value.")
    end
    @database = database[1..-1] if database.starts_with?('/')

    io << "/#{database}"
  end

  private def set_url_port(io)
    @port = port.strip

    io << ":#{port}" unless port.empty?
  end

  private def set_url_host(io)
    @hostname = hostname.strip

    io << hostname unless hostname.empty?
  end

  private def set_url_creds(io)
    @username = username.strip
    @password = password.strip
    io << URI.encode_www_form(username) unless username.empty?
    io << ":#{URI.encode_www_form(password)}" unless password.empty?
    io << "@" unless username.empty?
  end

  private def set_url_protocol(io)
    io << "postgres://"
  end

  private def set_url_query(io)
    @query = query.strip

    io << "?#{query}" unless query.empty?
  end
end
