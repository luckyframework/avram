class Avram::Migrator::ChangeColumnTypeStatement
  getter table_name, column_name

  alias ColumnType = Int32.class | Int64.class

  def initialize(@table_name : Symbol, @column_name : Symbol, @column_type : ColumnType)
  end

  def build
    String.build do |statement|
      statement << "ALTER TABLE #{table_name} "
      statement << "ALTER COLUMN #{column_name} "
      statement << "SET DATA TYPE #{psql_type(@column_type)}"
      statement << ";"
    end
  end

  def psql_type(column_type : ColumnType) : String
    case column_type
    when Int32.class
      "integer"
    when Int64.class
      "bigint"
    else
      raise <<-ERROR
        Avram doesn't know how to convert #{column_type} to a PostgreSQL type.

        The supported types are:

        - Int32 (integer)
        - Int64 (bigint)

        If you like, you can use raw SQL instead:

        execute "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET DATA TYPE <psql data type>"


      ERROR
    end
  end
end
