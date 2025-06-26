require "file_utils"
require "spec"
require "../src/avram"
require "../src/lucky"
require "../src/lucky/tasks"
require "./support/models/base_model"
require "./support/models/**"
require "./support/factories/base_factory"
require "./support/factories/**"
require "./support/**"
require "./lucky/support/**"
require "../config/*"
require "../db/migrations/**"

Pulsar.enable_test_mode!

Log.dexter.configure(:none)
backend = Log::IOBackend.new(STDERR)
backend.formatter = Dexter::JSONLogFormatter.proc
Log.builder.bind("avram.*", :error, backend)

Avram.initialize_logging

Db::Create.new(quiet: true).run_task
Db::Migrate.new(quiet: true).run_task

Avram::SpecHelper.use_transactional_specs(TestDatabase)

Spec.before_each do
  # This clears args between each CLI task spec.
  ARGV.clear
  # All specs seem to run on the same Fiber,
  # so we set back to NullStore before each spec
  # to ensure queries aren't randomly cached
  Fiber.current.query_cache = LuckyCache::NullStore.new
end

Lucky::Session.configure do |settings|
  settings.key = "_app_session"
end

Lucky::Server.configure do |settings|
  settings.secret_key_base = "EPzB4/PA/JZxEhISPr7Ad5X+G73exX+qg8IKFjqwdx0="
  settings.host = "0.0.0.0"
  settings.port = 8080
end

Lucky::RouteHelper.configure do |settings|
  settings.base_uri = "luckyframework.org"
end

Lucky::ErrorHandler.configure do |settings|
  settings.show_debug_output = false
end

Lucky::ForceSSLHandler.configure do |settings|
  settings.enabled = true
end

Habitat.raise_if_missing_settings!
