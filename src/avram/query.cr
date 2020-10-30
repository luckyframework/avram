require "./queryable"

abstract class Avram::Query(T)
  # runs a SQL `TRUNCATE` on the current table
  def self.truncate
    query = self.new
    query.database.exec "TRUNCATE TABLE #{query.table_name}"
  end

  def schema_class
    T
  end

  def database : Avram::Database.class
    schema_class.database
  end

  def table_name
    schema_class.table_name
  end

  def primary_key_name
    schema_class.primary_key_name
  end

  private def escape_sql(value : Int32)
    value
  end

  private def escape_sql(value : String)
    PG::EscapeHelper.escape_literal(value)
  end
end
