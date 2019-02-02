database = "avram_dev"

Avram::Repo.configure do |settings|
  settings.url = ENV["DATABASE_URL"]? || Avram::PostgresURL.build(
    hostname: "localhost",
    database: database
  )
end
