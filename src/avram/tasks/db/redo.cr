require "colorize"

class Db::Redo < BaseTask
  summary "Rollback and run just the last migration"

  def help_message
    <<-TEXT
    #{summary}

    Example:

      lucky db.redo

    TEXT
  end

  def run_task
    Db::Rollback.new.run_task
    Db::Migrate.new.run_task
  end
end
