class Db::Schema::Dump < LuckyCli::Task
  summary "Export database schema to a sql file"

  def initialize(@dump_to : String? = nil, @quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    Exports/dumps the database schema to a sql file.

    You must specify the path that you want Avram to dump the sql to. Note
    that this dumps the schema but does not dump any data.

    Example:

      lucky db.schema.dump structure.sql

    TEXT
  end

  def call
    dump_to = @dump_to || ARGV.first? || raise "Must pass a file path to dump the db structure to"
    Avram::Migrator.run do
      Avram::Migrator::Runner.dump_db(dump_to, @quiet)
    end
  end
end
