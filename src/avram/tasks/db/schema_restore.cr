class Db::Schema::Restore < LuckyCli::Task
  summary "Restore database from a sql dump file"

  def initialize(@import_file_path : String? = nil, @quiet : Bool = false)
  end

  def call
    import_file_path = @import_file_path || ARGV.first? || raise "A path to the import SQL file must be provided"
    Avram::Migrator.run do
      Avram::Migrator::Runner.restore_db(import_file_path.as(String), @quiet)
    end
  end
end
