class LuckyRecord::Query
  getter :table
  @limit : Int32?
  @wheres = [] of LuckyRecord::Where::SqlClause
  @prepared_statement_placeholder = 0

  def initialize(@table : Symbol)
  end

  def to_sql
    [statement] + args
  end

  def statement
    join_sql [select_sql] + sql_condition_clauses
  end

  def statement_for_update(params)
    join_sql ["UPDATE #{table}", set_sql_clause(params)] + sql_condition_clauses
  end

  def args_for_update(params)
    params.values.map(&.to_s) + prepared_statement_values
  end

  private def set_sql_clause(params)
    "SET " + params.map do |key, value|
      "#{key} = #{next_prepared_statement_placeholder}"
    end.join(", ")
  end

  private def join_sql(clauses)
    clauses.reject do |clause|
      clause.nil? || clause.blank?
    end.join(" ")
  end

  def args
    prepared_statement_values
  end

  private def sql_condition_clauses
    [wheres_sql, limit_sql]
  end

  def limit(amount)
    @limit = amount
    self
  end

  private def select_sql
    "SELECT * FROM #{table}"
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
