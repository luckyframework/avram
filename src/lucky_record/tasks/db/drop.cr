require "colorize"

class Db::Drop < LuckyCli::Task
  summary "Drop the database"

  def call
    LuckyRecord::Migrator.run do
      LuckyRecord::Migrator::Runner.drop_db
      puts "Done dropping #{LuckyRecord::Migrator::Runner.db_name.colorize(:green)}"
    end
  end
end
