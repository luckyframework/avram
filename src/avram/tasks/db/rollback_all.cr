require "colorize"

class Db::RollbackAll < BaseTask
  summary "Rollback all migrations"

  def help_message
    <<-TEXT
    #{summary}

    You may also want to look at 'lucky db.drop'.

    Example:

      lucky db.rollback_all

    TEXT
  end

  def run_task
    Avram::Migrator::Runner.new.rollback_all
    puts "Done rolling back all migrations".colorize(:green)
  end
end
