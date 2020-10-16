class Db::Create < LuckyCli::Task
  alias Migrator = Avram::Migrator
  summary "Create the database"

  def initialize(@quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    #{summary}

    The database name is usually found in config/database.cr

    Examples:

      lucky db.create
      LUCKY_ENV=test lucky db.create # Create the test database

    TEXT
  end

  def call
    Migrator.run do
      Migrator::Runner.create_db(@quiet)
    end
  end
end
