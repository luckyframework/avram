require "colorize"

class Db::Drop < LuckyCli::Task
  summary "Drop the database"

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.drop_db
      puts "Done dropping #{Avram::Migrator::Runner.db_name.colorize(:green)}"
    end
  end
end
