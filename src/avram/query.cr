require "./queryable"

abstract class Avram::Query
  # runs a SQL `TRUNCATE` on the current table
  def self.truncate
    Avram::Database.run do |db|
      db.exec "TRUNCATE TABLE #{@@table_name}"
    end
  end

  private def escape_sql(value : Int32)
    value
  end

  private def escape_sql(value : String)
    PG::EscapeHelper.escape_literal(value)
  end
end
