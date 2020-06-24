class Db::Create < LuckyCli::Task
  alias AM = Avram::Migrator
  summary "Create the database"

  def initialize(@quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    #{summary}

    The database name is usually found in config/database.cr

    Examples:

      lucky db.create
      LUCKY_ENV=test lucky db.create # Create the test database

    TEXT
  end

  def call
    AM::Runner.run("psql -q -l #{connection_url}", output: IO::Memory.new)
    AM.run do
      AM::Runner.create_db(@quiet)
    end
  rescue
    uri = URI.parse(connection_url)
    raise Avram::ConnectionError.new(uri, Avram.settings.database_to_migrate)
  end

  private def connection_url : String
    Avram::PostgresURL.build(
      database: "",
      hostname: AM::Runner.db_host.to_s,
      username: AM::Runner.db_user.to_s,
      password: AM::Runner.db_password.to_s,
      port: AM::Runner.db_port.to_s
    )
  end
end
