class Db::RollbackAll < BaseTask
  summary "Rollback all migrations"

  help_message <<-TEXT
  #{task_summary}

  You may also want to look at 'lucky db.drop'.

  Example:

    lucky db.rollback_all

  TEXT

  def run_task
    Avram::Migrator::Runner.new.rollback_all
    puts "Done rolling back all migrations".colorize(:green)
  end
end
