require "colorize"

class Db::Migrate < LuckyCli::Task
  summary "Run any pending migrations"

  def initialize(@quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    #{summary}

    Examples:

      lucky db.migrate
      LUCKY_ENV=test lucky db.migrate # Runs migrations on the test database

    TEXT
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.new(@quiet).run_pending_migrations
    end
  end
end
