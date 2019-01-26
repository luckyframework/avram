require "colorize"

class Db::Rollback < LuckyCli::Task
  summary "Rollback the last migration"

  def call
    LuckyRecord::Migrator.run do
      LuckyRecord::Migrator::Runner.new.rollback_one
    end
  end
end
