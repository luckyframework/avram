class Db::Console < LuckyTask::Task
  summary "Access PostgreSQL console"

  def help_message
    <<-TEXT
    #{summary}

    Enters the postgres REPL. Check config/database.cr
    for database configuration.

    Examples:

      lucky db.console

    TEXT
  end

  def call
    puts banner_message
    system("psql #{Avram::Migrator::Runner.credentials.url_without_query_params}")
  end

  private def banner_message
    String.build do |str|
      str << banner_header
      str << banner_help
    end
  end

  private def banner_header
    <<-MESSAGE.colorize(:green)
    Entering PSQL for #{Avram::Migrator::Runner.db_name}

    MESSAGE
  end

  private def banner_help
    <<-MESSAGE.colorize.dim
    Type '\\q' or 'exit' to leave
    MESSAGE
  end
end
