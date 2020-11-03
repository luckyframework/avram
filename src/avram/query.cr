require "./queryable"

abstract class Avram::Query(T)
  # runs a SQL `TRUNCATE` on the current table
  def self.truncate
    query = self.new
    query.database.exec "TRUNCATE TABLE #{query.table_name}"
  end

  delegate :database, :table_name, :primary_key_name, to: T

  def schema_class
    T
  end

  private def escape_sql(value : Int32)
    value
  end

  private def escape_sql(value : String)
    PG::EscapeHelper.escape_literal(value)
  end
end
