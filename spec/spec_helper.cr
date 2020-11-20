require "file_utils"
require "spec"
require "../src/avram"
require "./support/models/base_model"
require "./support/models/**"
require "./support/boxes/base_box"
require "./support/boxes/**"
require "./support/**"
require "../config/*"
require "../db/migrations/**"

Pulsar.enable_test_mode!

backend = Log::IOBackend.new(STDERR)
backend.formatter = Dexter::JSONLogFormatter.proc
Log.builder.bind("avram.*", :error, backend)

Db::Create.new(quiet: true).call
Db::Migrate.new(quiet: true).call
Db::VerifyConnection.new(quiet: true).call

Spec.before_each do
  TestDatabase.truncate
end

class SampleBackupDatabase < Avram::Database
end

SampleBackupDatabase.configure do |settings|
  settings.credentials = Avram::Credentials.parse?(ENV["BACKUP_DATABASE_URL"]?) || Avram::Credentials.new(
    hostname: "db",
    database: "sample_backup",
    username: "lucky",
    password: "developer"
  )
end

Habitat.raise_if_missing_settings!
