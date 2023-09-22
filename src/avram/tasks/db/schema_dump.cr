class Db::Schema::Dump < BaseTask
  summary "Export database schema to a sql file"
  help_message <<-TEXT
  #{task_summary}

  You must specify the path that you want Avram to dump the sql to. Note
  that this dumps the schema but does not dump any data.

  Example:

    lucky db.schema.dump structure.sql

  TEXT

  positional_arg :dump_to, "The path to store the SQL file"

  def initialize(@quiet : Bool = false)
  end

  def run_task
    Avram::Migrator::Runner.dump_db(dump_to, @quiet)
  end
end
