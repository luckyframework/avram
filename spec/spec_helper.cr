require "spec"
require "../src/avram"
require "./support/**"
require "../config/database"

Spec.before_each do
  Avram::Repo.truncate
end
