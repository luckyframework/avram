class Db::Reset < BaseTask
  summary "Drop, recreate, and run migrations."
  help_message <<-TEXT
  #{task_summary}

  Example:

    lucky db.reset

  To drop the test database:

     LUCKY_ENV=test lucky db.reset

  TEXT

  def initialize(@quiet : Bool = false)
  end

  def run_task
    Db::Drop.new(@quiet).run_task
    Db::Create.new(@quiet).run_task
    Db::Migrate.new(@quiet).run_task
  end
end
