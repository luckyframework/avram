database = "lucky_record_dev"

LuckyRecord::Repo.configure do |settings|
  settings.url = ENV["DATABASE_URL"]? || LuckyRecord::PostgresURL.build(
    hostname: "localhost",
    database: database
  )
end
