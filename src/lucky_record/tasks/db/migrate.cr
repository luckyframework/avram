require "colorize"

class Db::Migrate < LuckyCli::Task
  summary "Migrate the database"

  def initialize(@quiet : Bool = false)
  end

  def call
    LuckyRecord::Migrator.run do
      LuckyRecord::Migrator::Runner.new(@quiet).run_pending_migrations
    end
  end
end
