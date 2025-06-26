class Avram::Migrator::DropTableStatement
  def initialize(@table_name : TableName, @if_exists : Bool = false)
  end

  def build
    "DROP TABLE #{@if_exists ? "IF EXISTS " : ""}#{@table_name};"
  end
end
