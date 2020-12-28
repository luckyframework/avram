require "colorize"

class Db::Migrate::One < BaseTask
  summary "Run just the next pending migration"

  def help_message
    <<-TEXT
    #{summary}

    Example:

      lucky db.migrate.one

    TEXT
  end

  def run_task
    Avram::Migrator::Runner.new.run_next_migration
  end
end
