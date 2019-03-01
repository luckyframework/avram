class Avram::QueryBuilder
  alias ColumnName = Symbol | String
  getter :table
  @limit : Int32?
  @offset : Int32?
  @wheres = [] of Avram::Where::SqlClause
  @raw_wheres = [] of Avram::Where::Raw
  @wheres_sql : String?
  @joins = [] of Avram::Join::SqlClause
  @orders = {
    asc:  [] of Symbol | String,
    desc: [] of Symbol | String,
  }
  @selections : String = "*"
  @prepared_statement_placeholder = 0
  @distinct : Bool = false
  @distinct_on : String | Symbol | Nil = nil

  VALID_DIRECTIONS = [:asc, :desc]

  def initialize(@table : Symbol)
  end

  def to_sql
    [statement] + args
  end

  def statement
    join_sql [select_sql] + sql_condition_clauses
  end

  def statement_for_update(params)
    join_sql ["UPDATE #{table}", set_sql_clause(params)] + sql_condition_clauses + ["RETURNING #{@selections}"]
  end

  def args_for_update(params)
    param_values(params) + prepared_statement_values
  end

  private def param_values(params)
    params.values.map do |value|
      if value.nil?
        nil
      else
        value.to_s
      end
    end
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
    [joins_sql, wheres_sql, order_sql, limit_sql, offset_sql]
  end

  def distinct
    @distinct = true
    self
  end

  def distinct_on(column : Symbol | String)
    @distinct_on = column
    self
  end

  private def distinct?
    @distinct || @distinct_on
  end

  def limit(amount)
    @limit = amount
    self
  end

  def offset(@offset)
    self
  end

  def order_by(column, direction : Symbol)
    raise "Direction must be :asc or :desc, got #{direction}" unless VALID_DIRECTIONS.includes?(direction)
    @orders[direction] << column
    self
  end

  def reverse_order
    @orders = {
      asc:  @orders[:desc],
      desc: @orders[:asc],
    }
    self
  end

  def order_sql
    if ordered?
      "ORDER BY " + @orders.map do |direction, columns|
        next if columns.empty?
        "#{columns.join(" #{direction.to_s.upcase}, ")} #{direction.to_s.upcase}"
      end.reject(&.nil?).join(", ")
    end
  end

  def select_count
    add_aggregate "COUNT(*)"
  end

  def select_min(column : ColumnName)
    add_aggregate "MIN(#{column})"
  end

  def select_max(column : ColumnName)
    add_aggregate "MAX(#{column})"
  end

  def select_average(column : ColumnName)
    add_aggregate "AVG(#{column})"
  end

  def select_sum(column : ColumnName)
    add_aggregate "SUM(#{column})"
  end

  private def add_aggregate(sql : String)
    raise_if_query_has_unsupported_statements
    @selections = sql
    reset_order
    self
  end

  private def raise_if_query_has_unsupported_statements
    if has_unsupported_clauses?
      raise Avram::UnsupportedQueryError.new(<<-ERROR
        Can't use aggregates (count, min, etc.) with limit or offset.

        Try calling 'results' on your query and use the Array and Enumerable
        methods in Crystal instead of using the database.
        ERROR
      )
    end
  end

  private def has_unsupported_clauses?
    @limit || @offset
  end

  private def reset_order
    @orders.values.each(&.clear)
  end

  def select(selection : Array(Symbol))
    @selections = selection
      .map { |column| "#{@table}.#{column}" }
      .join(", ")
    self
  end

  def ordered?
    @orders.values.any? do |columns|
      columns.any?
    end
  end

  private def select_sql
    String.build do |sql|
      sql << "SELECT "
      sql << "DISTINCT " if distinct?
      sql << "ON (#{@distinct_on}) " if @distinct_on
      sql << @selections
      sql << " FROM "
      sql << table
    end
  end

  private def limit_sql
    if @limit
      "LIMIT #{@limit}"
    end
  end

  private def offset_sql
    if @offset
      "OFFSET #{@offset}"
    end
  end

  def join(join_clause : Avram::Join::SqlClause)
    @joins << join_clause
    self
  end

  private def joins_sql
    @joins.map(&.to_sql).join(" ")
  end

  def where(where_clause : Avram::Where::SqlClause)
    @wheres << where_clause
    self
  end

  def raw_where(where_clause : Avram::Where::Raw)
    @raw_wheres << where_clause
    self
  end

  private def wheres_sql
    @wheres_sql ||= joined_wheres_queries
  end

  private def joined_wheres_queries
    if @wheres.any? || @raw_wheres.any?
      statements = @wheres.map do |sql_clause|
        if sql_clause.is_a?(Avram::Where::NullSqlClause)
          sql_clause.prepare
        else
          sql_clause.prepare(next_prepared_statement_placeholder)
        end
      end
      statements += @raw_wheres.map(&.to_sql)

      "WHERE " + statements.join(" AND ")
    end
  end

  private def prepared_statement_values
    @wheres.uniq.compact_map do |sql_clause|
      sql_clause.value unless sql_clause.is_a?(Avram::Where::NullSqlClause)
    end
  end

  private def next_prepared_statement_placeholder
    @prepared_statement_placeholder += 1
    "$#{@prepared_statement_placeholder}"
  end
end
