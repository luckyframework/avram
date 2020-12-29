require "colorize"

class Db::Reset < BaseTask
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

  def run_task
    Db::Drop.new.run_task
    Db::Create.new.run_task
    Db::Migrate.new.run_task
  end
end
