class Db::Create < LuckyCli::Task
  summary "Create the database"

  def initialize(@quiet : Bool = false)
  end

  def call
    Avram::Migrator.run do
      Avram::Migrator::Runner.create_db(@quiet)
    end
  end
end
