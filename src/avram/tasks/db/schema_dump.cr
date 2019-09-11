class Db::Schema::Dump < LuckyCli::Task
  summary "Export database schema to a sql file"

  def initialize(@dump_to : String? = nil, @quiet : Bool = false)
  end

  def call
    dump_to = @dump_to || ARGV.first? || raise "Must pass a file path to dump the db structure to"
    Avram::Migrator.run do
      Avram::Migrator::Runner.dump_db(dump_to, @quiet)
    end
  end
end
