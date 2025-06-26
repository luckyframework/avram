class Db::Migrate < BaseTask
  summary "Run any pending migrations"
  help_message <<-TEXT
  #{task_summary}

  Examples:

    lucky db.migrate
    LUCKY_ENV=test lucky db.migrate # Runs migrations on the test database

  TEXT

  def initialize(@quiet : Bool = false)
  end

  def run_task
    Avram::Migrator::Runner.new(@quiet).run_pending_migrations
  end
end
