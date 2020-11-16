abstract class Avram::Migrator::Columns::PrimaryKeys::Base
  macro inherited
    private getter name : String
  end

  abstract def column_type

  def build : String
    %(  #{name} #{column_type} PRIMARY KEY)
  end
end
