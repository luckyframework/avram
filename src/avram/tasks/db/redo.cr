require "colorize"

class Db::Redo < LuckyCli::Task
  summary "Rollback then run the last migration"

  def call
    Db::Rollback.new.call
    Db::Migrate.new.call
  end
end
