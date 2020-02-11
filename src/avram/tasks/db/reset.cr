require "colorize"

class Db::Reset < LuckyCli::Task
  summary "Drop, recreate, and run migrations."

  def help_message
    <<-TEXT
    #{summary}

    Example:

      lucky db.reset

    To drop the test database:

       LUCKY_ENV=test lucky db.reset

    TEXT
  end

  def call
    Db::Drop.new.call
    Db::Create.new.call
    Db::Migrate.new.call
  end
end
