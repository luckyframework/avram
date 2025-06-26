class Db::Redo < BaseTask
  summary "Rollback and run just the last migration"
  help_message <<-TEXT
  #{task_summary}

  Example:

    lucky db.redo

  TEXT

  def run_task
    Db::Rollback.new.run_task
    Db::Migrate.new.run_task
  end
end
