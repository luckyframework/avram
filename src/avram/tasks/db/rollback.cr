class Db::Rollback < BaseTask
  summary "Rollback the last migration"
  help_message <<-TEXT
  #{task_summary}

  Example:

    lucky db.rollback

  TEXT

  def run_task
    Avram::Migrator::Runner.new.rollback_one
  end
end
