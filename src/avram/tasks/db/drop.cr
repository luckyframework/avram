class Db::Drop < BaseTask
  summary "Drop the database"
  help_message <<-TEXT
  #{task_summary}

  The database name is usually found in config/database.cr

  Examples:

    lucky db.drop
    LUCKY_ENV=test lucky db.drop # Drop the test database

  TEXT

  def initialize(@quiet : Bool = false)
  end

  def run_task
    Avram::Migrator::Runner.drop_db(@quiet)
  end
end
