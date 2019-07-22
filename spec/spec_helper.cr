require "spec"
require "../src/avram"
require "./support/base_model"
require "./support/**"
require "../config/database"

Db::Create.new(quiet: true).call
Db::Migrate.new(quiet: true).call

Spec.before_each do
  TestDatabase.truncate
end

Habitat.raise_if_missing_settings!
