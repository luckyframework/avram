class Db::Create < BaseTask
  alias Migrator = Avram::Migrator
  summary "Create the database"
  help_message <<-TEXT
  #{task_summary}

  The database name is usually found in config/database.cr

  Examples:

    lucky db.create
    LUCKY_ENV=test lucky db.create # Create the test database

  TEXT

  def initialize(@quiet : Bool = false)
  end

  def run_task
    Migrator::Runner.create_db(@quiet)
  end
end
