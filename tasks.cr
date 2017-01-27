require "lucky_cli"
require "lucky_migrator"
require "./db/migrations/*"

class Db::Reset < LuckyCli::Task
  banner "Drop, creates and migrates the database"

  def call
    run("lucky db.drop")
    run("lucky db.create")
    run("lucky db.migrate")
  end

  private def run(command)
    Process.run(command, shell: true, output: true, error: true)
  end
end

LuckyMigrator::Runner.db_name = "lucky_record_test"

LuckyCli::Runner.run
