require "spec"
require "../src/avram"
require "./support/base_model"
require "./support/**"
require "../config/database"

Db::Create.new.call
Db::Migrate.new.call

Spec.before_each do
  TestDatabase.truncate
end

Habitat.raise_if_missing_settings!
