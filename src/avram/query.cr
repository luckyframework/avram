require "./queryable"

abstract class Avram::Query
  abstract def database : Avram::Database.class

  # runs a SQL `TRUNCATE` on the current table
  def self.truncate
    query = new
    query.database.exec "TRUNCATE TABLE #{query.table_name}"
  end

  private def escape_sql(value : Int32)
    value
  end

  private def escape_sql(value : String)
    PG::EscapeHelper.escape_literal(value)
  end
end
