require "colorize"

class Db::Rollback < BaseTask
  summary "Rollback the last migration"

  def help_message
    <<-TEXT
    #{summary}

    Example:

      lucky db.rollback

    TEXT
  end

  def run_task
    Avram::Migrator::Runner.new.rollback_one
  end
end
