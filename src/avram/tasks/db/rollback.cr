require "colorize"

class Db::Rollback < LuckyCli::Task
  summary "Rollback the last migration"

  def help_message
    <<-TEXT
    Rollback the last migration.

    Example:

      lucky db.rollback

    TEXT
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.new.rollback_one
    end
  end
end
