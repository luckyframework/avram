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
    Process.run(command, shell: true, output: STDOUT, error: STDERR)
  end
end

database = "lucky_record_test"

LuckyRecord::Repo.configure do
  if ENV["DATABASE_URL"]?
    settings.url = ENV["DATABASE_URL"]
  else
    settings.url = LuckyRecord::PostgresURL.build(
      database: "lucky_record_test",
      hostname: "localhost"
    )
  end
end

LuckyMigrator::Runner.configure do
  settings.database = database
end

LuckyCli::Runner.run
