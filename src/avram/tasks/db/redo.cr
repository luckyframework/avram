require "colorize"

class Db::Redo < LuckyCli::Task
  summary "Rollback and run just the last migration"

  def help_message
    <<-TEXT
    #{summary}

    Example:

      lucky db.redo

    TEXT
  end

  def call
    Db::Rollback.new.call
    Db::Migrate.new.call
  end
end
