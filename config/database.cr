database_name = "avram_dev"

# Adding this struct makes everything work
#
# Removing it causes:
#
# BUG: trying to upcast Dexter::Formatters::JsonLogFormatter <- Dexter::Formatters::BaseLogFormatter (Exception)
#   from ???
#   from ???
#   from ???
struct NotEvenUsedAnywhere < Dexter::Formatters::BaseLogFormatter
  def format(data) : Void
    # do nothing
  end
end

Avram::Repo.configure do |settings|
  settings.url = ENV["DATABASE_URL"]? || Avram::PostgresURL.build(
    hostname: "db",
    database: database_name,
    username: "lucky",
    password: "developer"
  )
end
