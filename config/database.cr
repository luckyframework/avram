database_name = "avram_dev"

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

class SampleBackupDatabase < Avram::Database
end

SampleBackupDatabase.configure do |settings|
  settings.credentials = Avram::Credentials.parse?(ENV["BACKUP_DATABASE_URL"]?) || Avram::Credentials.new(
    hostname: "db",
    database: "sample_backup",
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

# One connection and no transactional spec wrapper (`use_transactional_specs`
# only wraps `TestDatabase`, and it hides connection reuse bugs: a connection
# with an open transaction is never released). With one connection, "another
# fiber got my connection while I was still using it" is deterministic, and
# `max_idle_pool_size=1` exposes a double release: the second release finds
# the idle pool full and closes the connection.
# See spec/avram/database_connection_reuse_spec.cr
class SingleConnectionDatabase < Avram::Database
end

SingleConnectionDatabase.configure do |settings|
  uri = TestDatabase.credentials.uri.dup
  uri.query = "initial_pool_size=1&max_pool_size=1&max_idle_pool_size=1&checkout_timeout=0.3"
  settings.credentials = Avram::Credentials.new(uri)
end

Avram.configure do |settings|
  settings.database_to_migrate = TestDatabase
end
