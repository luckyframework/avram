class Avram::Migrator::DropTableStatement
  def initialize(@table_name : TableName)
  end

  def build
    "DROP TABLE #{@table_name}"
  end
end
