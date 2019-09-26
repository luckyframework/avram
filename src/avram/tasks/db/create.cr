class Db::Create < LuckyCli::Task
  summary "Create the database"

  def initialize(@quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    Creates the database.

    The database name is usually found in config/database.cr

    Examples:

      lucky db.create
      LUCKY_ENV=test lucky db.create # Create the test database

    TEXT
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.create_db(@quiet)
    end
  end
end
