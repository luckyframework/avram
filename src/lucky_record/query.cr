class LuckyRecord::Query
  private getter :table
  @limit : Int32?
  @wheres = [] of LuckyRecord::Where::SqlClause
  @prepared_statement_placeholder = 0

  def initialize(@table : Symbol)
  end

  def to_sql
    [sql_clauses.reject do |clause|
      clause.nil? || clause.blank?
    end.join(" ")] + prepared_statement_values
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
      "WHERE " + @wheres.map(&.prepare(next_prepared_statement_placeholder)).join(" AND ")
    end
  end

  private def prepared_statement_values
    @wheres.map(&.value)
  end

  private def next_prepared_statement_placeholder
    @prepared_statement_placeholder += 1
    "$#{@prepared_statement_placeholder}"
  end
end
