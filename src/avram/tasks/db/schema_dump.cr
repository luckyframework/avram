class Db::Schema::Dump < LuckyCli::Task
  summary "Export database schema to a sql file"

  def initialize(@quiet : Bool = false)
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.dump_db(@quiet)
    end
  end
end
