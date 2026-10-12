class Avram::Migrator::DropFunctionStatement
  def initialize(@name : String)
  end

  def build
    <<-SQL
    DROP FUNCTION IF EXISTS "#{@name}" CASCADE;
    SQL
  end
end
