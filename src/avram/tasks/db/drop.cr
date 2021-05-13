require "colorize"

class Db::Drop < BaseTask
  summary "Drop the database"

  def initialize(@quiet : Bool = false)
  end

  def run_task
    Avram::Migrator::Runner.drop_db(@quiet)
  end

  def help_message
    <<-TEXT
    #{summary}

    The database name is usually found in config/database.cr

    Examples:

      lucky db.drop
      LUCKY_ENV=test lucky db.drop # Drop the test database

    TEXT
  end
end
