class Db::Schema::Restore < LuckyCli::Task
  summary "Restore database from a sql dump file"

  def initialize(@import_file_path : String? = nil, @quiet : Bool = false)
  end

  def help_message
    <<-TEXT
    Restores the database from a sql dump file.

    You must specify the path to the sql that you want Avram to restore from.

    Example:

      lucky db.schema.restore structure.sql

    TEXT
  end

  def call
    import_file_path = @import_file_path || ARGV.first? || raise "A path to the import SQL file must be provided"
    Avram::Migrator.run do
      Avram::Migrator::Runner.restore_db(import_file_path.as(String), @quiet)
    end
  end
end
