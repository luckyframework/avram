database_name = "avram_dev"

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
