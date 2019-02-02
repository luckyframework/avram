require "colorize"

class Db::Rollback < LuckyCli::Task
  summary "Rollback the last migration"

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.new.rollback_one
    end
  end
end
