require "colorize"

class Db::RollbackAll < LuckyCli::Task
  summary "Rollback all migrations"

  def call
    LuckyRecord::Migrator.run do
      LuckyRecord::Migrator::Runner.new.rollback_all
      puts "Done rolling back all migrations".colorize(:green)
    end
  end
end
