require "colorize"

class Db::Reset < BaseTask
  summary "Drop, recreate, and run migrations."

  def initialize(@quiet : Bool = false)
  end

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
    Db::Drop.new(@quiet).run_task
    Db::Create.new(@quiet).run_task
    Db::Migrate.new(@quiet).run_task
  end
end
