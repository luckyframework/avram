class LuckyRecord::Query
  private getter :table
  @limit : Int32?
  @wheres = [] of LuckyRecord::Where::SqlClause

  def initialize(@table : Symbol)
  end

  def to_sql
    sql_clauses.reject do |clause|
      clause.nil? || clause.blank?
    end.join(" ")
  end

  private def sql_clauses
    [select_sql, wheres_sql, limit_sql]
  end

  private def select_sql
    "SELECT * FROM #{table}"
  end

  def limit(amount)
    @limit = amount
    self
  end

  private def limit_sql
    if @limit
      "LIMIT #{@limit}"
    end
  end

  def where(where_clause : LuckyRecord::Where::SqlClause)
    @wheres << where_clause
    self
  end

  private def wheres_sql
    if @wheres.any?
      "WHERE " + @wheres.map(&.to_sql).join(" AND ")
    end
  end
end
