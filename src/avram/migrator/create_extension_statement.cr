class Avram::Migrator::CreateExtensionStatement
  def initialize(@name : String)
  end

  def build
    <<-SQL
    CREATE EXTENSION IF NOT EXISTS "#{@name}";
    SQL
  end
end
