class LuckyRecord::Query
  private getter :table
  @limit : Int32?
  @wheres = [] of String

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

  def where_eq(column, value)
    @wheres << "WHERE #{column} = #{value}"
    self
  end

  def where_gt(column, value)
    @wheres << "WHERE #{column} > #{value}"
    self
  end

  def where_gte(column, value)
    @wheres << "WHERE #{column} >= #{value}"
    self
  end

  def where_lt(column, value)
    @wheres << "WHERE #{column} < #{value}"
    self
  end

  def where_lte(column, value)
    @wheres << "WHERE #{column} <= #{value}"
    self
  end

  private def wheres_sql
    @wheres.join(" ")
  end
end
