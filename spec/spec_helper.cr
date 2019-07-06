require "spec"
require "../src/avram"
require "./support/**"
require "../config/database"

Db::Create.new.call
Db::Migrate.new.call

Spec.before_each do
  Avram::Database.truncate
end
