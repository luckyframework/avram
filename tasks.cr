require "lucky_cli"
require "./src/lucky_record"
require "./config/database"
require "./db/migrations/*"

class Db::Reset < LuckyCli::Task
  summary "Drop, creates and migrates the database"

  def call
    run("lucky db.drop")
    run("lucky db.create")
    run("lucky db.migrate")
  end

  private def run(command)
    Process.run(command, shell: true, output: STDOUT, error: STDERR)
  end
end

LuckyCli::Runner.run
