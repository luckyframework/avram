require "colorize"

class Db::Migrate::One < LuckyCli::Task
  summary "Run just the next pending migration"

  def help_message
    <<-TEXT
    #{summary}

    Example:

      lucky db.migrate.one

    TEXT
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.new.run_next_migration
    end
  end
end
