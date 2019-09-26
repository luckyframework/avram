require "colorize"

class Db::Migrate < LuckyCli::Task
  summary "Migrate the database"

  def initialize(@quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    Runs any pending migrations.

    Examples:

      lucky db.migrate
      LUCKY_ENV=test lucky db.migrat # Runs migrations onthe test database

    TEXT
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.new(@quiet).run_pending_migrations
    end
  end
end
