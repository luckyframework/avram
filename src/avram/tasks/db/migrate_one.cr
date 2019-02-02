require "colorize"

class Db::Migrate::One < LuckyCli::Task
  summary "Run the next pending migration"

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.new.run_next_migration
    end
  end
end
