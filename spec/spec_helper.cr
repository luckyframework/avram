require "file_utils"
require "spec"
require "../src/avram"
require "./support/models/base_model"
require "./support/models/**"
require "./support/factories/base_factory"
require "./support/factories/**"
require "./support/**"
require "../config/*"
require "../db/migrations/**"

Pulsar.enable_test_mode!

backend = Log::IOBackend.new(STDERR)
backend.formatter = Dexter::JSONLogFormatter.proc
Log.builder.bind("avram.*", :error, backend)

Db::Create.new(quiet: true).run_task
Db::Migrate.new(quiet: true).run_task
Db::VerifyConnection.new(quiet: true).run_task
TestDatabase.connections.clear # remove the reference to the connection used to setup the database

Spec.around_each do |spec|
  disable_transaction = false
  current = spec.example
  while !disable_transaction && !current.is_a?(Spec::RootContext)
    temp = current.as(Spec::Item)
    disable_transaction = temp.tags.try(&.includes?("disable_transaction"))
    current = temp.parent
  end

  if disable_transaction
    spec.run
    TestDatabase.truncate
    next
  end

  tracked_transactions = [] of DB::Transaction

  TestDatabase.setup_connection do |conn|
    tracked_transactions << conn.begin_transaction.tap(&.joinable=(false))
  end

  lock_id = Fiber.current.object_id
  TestDatabase.lock_id = lock_id
  TestDatabase.new.current_connection

  spec.run

  tracked_transactions.each do |transaction|
    next if transaction.closed? || transaction.connection.closed?

    transaction.rollback
    transaction.connection.release
  end
  tracked_transactions.clear
  TestDatabase.connections.clear
  TestDatabase.setup_connection { }
end

Spec.before_each do
  # All specs seem to run on the same Fiber,
  # so we set back to NullStore before each spec
  # to ensure queries aren't randomly cached
  Fiber.current.query_cache = LuckyCache::NullStore.new
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
