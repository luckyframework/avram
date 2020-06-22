class Db::Create < LuckyCli::Task
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
    result, output = run_connection_check
    if result.exit_code == 0
      Avram::Migrator.run do
        Avram::Migrator::Runner.create_db(@quiet)
      end
    else
      uri = URI.parse(connection_url)
      raise Avram::ConnectionError.new(uri, Avram.settings.database_to_migrate)
    end
  end

  private def connection_url : String
    Avram::PostgresURL.build(
      database: "",
      hostname: Avram::Migrator::Runner.db_host.to_s,
      username: Avram::Migrator::Runner.db_user.to_s,
      password: Avram::Migrator::Runner.db_password.to_s,
      port: Avram::Migrator::Runner.db_port.to_s
    )
  end

  private def run_connection_check
    output = IO::Memory.new
    command = "psql -q -l #{connection_url}"
    process = Process.run(
      command,
      shell: true,
      input: :close,
      output: output,
      error: STDERR
    )
    {process, output}
  end
end
