database_name = "avram_dev"

Avram::Database.configure do |settings|
  settings.url = ENV["DATABASE_URL"]? || Avram::PostgresURL.build(
    hostname: "db",
    database: database_name,
    username: "lucky",
    password: "developer"
  )
end
