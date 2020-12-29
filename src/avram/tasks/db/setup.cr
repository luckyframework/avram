class Db::Setup < BaseTask
  summary "Runs a few tasks for setting up your database"

  def initialize(@quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    #{summary}

    This task will run the following:
      * db.create   - Create the database from config/database.cr
      * db.migrate  - Migrate all pending migrations from db/migrations/


    Examples:

      lucky db.setup
      LUCKY_ENV=test lucky db.setup # Setup test database

    TEXT
  end

  def run_task
    Avram::Migrator::Runner.create_db(@quiet)
    Avram::Migrator::Runner.new(@quiet).run_pending_migrations
  end
end
