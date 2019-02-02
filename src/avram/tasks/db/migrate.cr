require "colorize"

class Db::Migrate < LuckyCli::Task
  summary "Migrate the database"

  def initialize(@quiet : Bool = false)
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.new(@quiet).run_pending_migrations
    end
  end
end
