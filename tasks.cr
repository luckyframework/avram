require "lucky_cli"
require "lucky_migrator"
require "./db/migrations/*"

LuckyMigrator::Runner.db_name = "lucky_record_test"

LuckyCli::Runner.run
