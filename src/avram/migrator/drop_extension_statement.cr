class Avram::Migrator::DropExtensionStatement
  def initialize(@name : String)
  end

  def build
    <<-SQL
    DROP EXTENSION IF EXISTS "#{@name}" CASCADE;
    SQL
  end
end
