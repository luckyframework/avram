class Db::Schema::Restore < LuckyCli::Task
  summary "Restore database from a sql dump file"

  def initialize(@import_file : String? = nil, @quiet : Bool = false)
  end

  def call
    import_file = @import_file || ARGV.first? || raise "An import file must be provided"
    Avram::Migrator.run do
      Avram::Migrator::Runner.restore_db(import_file.as(String), @quiet)
    end
  end
end
