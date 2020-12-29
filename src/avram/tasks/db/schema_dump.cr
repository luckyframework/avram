class Db::Schema::Dump < BaseTask
  summary "Export database schema to a sql file"

  def initialize(@dump_to : String? = nil, @quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    #{summary}

    You must specify the path that you want Avram to dump the sql to. Note
    that this dumps the schema but does not dump any data.

    Example:

      lucky db.schema.dump structure.sql

    TEXT
  end

  def run_task
    dump_to = @dump_to || ARGV.first? || raise "Must pass a file path to dump the db structure to"
    Avram::Migrator::Runner.dump_db(dump_to, @quiet)
  end
end
