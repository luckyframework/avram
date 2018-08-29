require "spec"
require "../src/lucky_record"
require "./support/**"
require "../config/database"

Spec.before_each do
  LuckyRecord::Repo.truncate
end
