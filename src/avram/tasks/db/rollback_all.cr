require "colorize"

class Db::RollbackAll < LuckyCli::Task
  summary "Rollback all migrations"

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.new.rollback_all
      puts "Done rolling back all migrations".colorize(:green)
    end
  end
end
