database_name = "avram_dev"

class TestDatabase < Avram::Database
end

class DatabaseWithIncorrectSettings < Avram::Database
end

TestDatabase.configure do |settings|
  settings.url = ENV["DATABASE_URL"]? || Avram::PostgresURL.build(
    hostname: "db",
    database: database_name,
    username: "lucky",
    password: "developer"
  )
end

DatabaseWithIncorrectSettings.configure do |settings|
  settings.url = Avram::PostgresURL.build(
    hostname: "db",
    database: database_name,
    username: "incorrect"
  )
end

Avram.configure do |settings|
  settings.database_to_migrate = TestDatabase.new
end
