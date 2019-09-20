require "file_utils"
require "spec"
require "../src/avram"
require "./support/base_model"
require "./support/**"
require "../config/database"

Db::VerifyConnection.new(quiet: true).call
Db::Create.new(quiet: true).call
Db::Migrate.new(quiet: true).call

Spec.before_each do
  TestDatabase.truncate
end

class SampleBackupDatabase < Avram::Database
end

SampleBackupDatabase.configure do |settings|
  settings.url = ENV["BACKUP_DATABASE_URL"]? || Avram::PostgresURL.build(
    hostname: "db",
    database: "sample_backup",
    username: "lucky",
    password: "developer"
  )
end

Habitat.raise_if_missing_settings!
