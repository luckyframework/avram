database_name = "avram_dev"

module DbType
  def self.cockroachdb?
    ENV["DATABASE_TYPE"]? == "cockroachdb"
  end
end

class TestDatabase < Avram::Database
end

class DatabaseWithIncorrectSettings < Avram::Database
end

TestDatabase.configure do |settings|
  settings.credentials = Avram::Credentials.parse?(ENV["DATABASE_URL"]?) || Avram::Credentials.new(
    hostname: "db",
    database: database_name,
    username: "lucky",
    password: "developer"
  )
end

DatabaseWithIncorrectSettings.configure do |settings|
  settings.credentials = Avram::Credentials.new(
    hostname: "db",
    database: database_name,
    username: "incorrect"
  )
end

Avram.configure do |settings|
  settings.database_to_migrate = TestDatabase
end
