require "colorize"

class Db::RollbackTo < LuckyCli::Task
  summary "Rollback to a specific migration"

  def help_message
    <<-TEXT
    #{summary}

    You can get the migration version from the filename or by running 'lucky db.migration.status'

    Example:

      lucky db.rollback_to 20180802180356

    TEXT
  end

  def call
    Avram::Migrator.run do
      version = ARGV.first?
      if version && version.to_i64?
        Avram::Migrator::Runner.new.rollback_to(version.to_i64)
      else
        raise "Migration version is required. Example: lucky db.rollback_to 20180802180356".colorize(:red).to_s
      end
    end
  end
end
