require "colorize"

class Db::Drop < LuckyCli::Task
  summary "Drop the database"

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.drop_db
      puts "Done dropping #{Avram::Migrator::Runner.db_name.colorize(:green)}"
    end
  end

  def help_message
    <<-TEXT
    #{summary}

    The database name is usually found in config/database.cr

    Examples:

      lucky db.drop
      LUCKY_ENV=test lucky db.drop # Drop the test database

    TEXT
  end
end
