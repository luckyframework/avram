require "spec"
require "../src/lucky_record"
require "./support/**"
require "../config/database"

LuckyRecord::Repo.configure do
  if ENV["DATABASE_URL"]?
    settings.url = ENV["DATABASE_URL"]
  else
    settings.url = LuckyRecord::PostgresURL.build(
      database: "lucky_record_test",
      hostname: "localhost"
    )
  end
end

Spec.before_each do
  LuckyRecord::Repo.truncate
end
