class LuckyRecord::PostgresURL
  getter database, username, password, hostname, port
  def initialize(
                 @database : String,
                 @hostname : String,
                 @username : String = "",
                 @password : String = "",
                 @port : String = ""
                 )
  end

  def self.build(**args)
    new(**args).build
  end

  def build
    String.build do |io|
      set_url_protocol(io)
      set_url_creds(io)
      set_url_host(io)
      set_url_port(io)
      set_url_db(io)
    end
  end

  private def set_url_db(io)
    io << "/#{database}"
  end

  private def set_url_port(io)
    io << ":#{port}" unless port == ""
  end

  private def set_url_host(io)
    io << hostname
  end

  private def set_url_creds(io)
    io << URI.escape(username) unless username.empty?
    io << ":#{URI.escape(password)}" unless password.empty?
    io << "@" unless username.empty?
  end

  private def set_url_protocol(io)
    io << "postgres://"
  end
end
