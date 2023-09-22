class Db::Migrate::One < BaseTask
  summary "Run just the next pending migration"
  help_message <<-TEXT
  #{task_summary}

  Example:

    lucky db.migrate.one

  TEXT

  def run_task
    Avram::Migrator::Runner.new.run_next_migration
  end
end
