class Avram::QueryBuilder
  def_clone

  alias ColumnName = Symbol | String
  getter table : TableName
  getter distinct_on : ColumnName | Nil = nil
  @limit : Int32?
  @offset : Int32?
  @wheres = [] of Avram::Where::Condition
  @joins = [] of Avram::Join::SqlClause
  @orders = [] of Avram::OrderByClause
  @groups = [] of ColumnName
  @selections : String = "*"
  @prepared_statement_placeholder = 0
  @distinct : Bool = false
  @delete : Bool = false

  def initialize(@table)
  end

  def to_sql
    [statement] + args
  end

  # Prepares the SQL statement by combining the `args` and `statement`
  # in to a single `String`
  def to_prepared_sql : String
    params = args.map { |arg| "'#{String.new(PQ::Param.encode(arg).slice)}'" }
    i = 0
    sql = statement
    sql.scan(/\$\d+/) do |match|
      sql = sql.sub(match[0], params[i])
      i += 1
    end
    sql
  end

  # Merges the wheres, joins, and orders from the passed in query
  def merge(query_to_merge : Avram::QueryBuilder)
    query_to_merge.wheres.each do |where|
      where(where)
    end

    query_to_merge.joins.each do |join|
      join(join)
    end

    query_to_merge.orders.each do |order|
      order_by(order)
    end

    query_to_merge.groups.each do |group|
      group_by(group)
    end
  end

  def statement
    clone.statement!
  end

  def statement!
    join_sql [@delete ? delete_sql : select_sql] + sql_condition_clauses
  end

  def statement_for_update(params, return_columns returning? : Bool = true)
    clone.statement_for_update!(params, returning?)
  end

  def statement_for_update!(params, return_columns returning? : Bool = true)
    sql = ["UPDATE #{table}", set_sql_clause(params)]
    sql += sql_condition_clauses
    sql += ["RETURNING #{@selections}"] if returning?

    join_sql sql
  end

  def args_for_update(params)
    param_values(params) + prepared_statement_values
  end

  private def param_values(params)
    params.values.map do |value|
      case value
      when Nil
        nil
      when JSON::Any
        value.to_json
      else
        value.to_s
      end
    end.to_a
  end

  private def set_sql_clause(params)
    "SET " + params.join(", ") do |key, _|
      "#{key} = #{next_prepared_statement_placeholder}"
    end
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
    [joins_sql, wheres_sql, group_sql, order_sql, limit_sql, offset_sql]
  end

  def delete
    @delete = true
    self
  end

  def distinct
    @distinct = true
    self
  end

  def distinct_on(column : ColumnName)
    @distinct_on = column
    self
  end

  def distinct?
    @distinct || has_distinct_on?
  end

  def has_distinct_on?
    !!@distinct_on
  end

  def limit
    @limit
  end

  def limit(@limit)
    self
  end

  def offset
    @offset
  end

  def offset(@offset)
    self
  end

  def order_by(order : OrderByClause)
    reset_order if ordered_randomly?
    @orders << order
    self
  end

  def random_order
    reset_order
    @orders << Avram::OrderByRandom.new
    self
  end

  def reset_where(column : ColumnName)
    @wheres.reject! { |clause| clause.is_a?(Avram::Where::SqlClause) && clause.column.to_s == column.to_s }
    self
  end

  def reset_order
    @orders.clear
  end

  def reverse_order
    @orders = @orders.map(&.reversed).reverse! unless ordered_randomly?
    self
  end

  def order_sql
    if ordered?
      "ORDER BY " + orders.join(", ", &.prepare)
    end
  end

  def orders
    @orders.uniq!(&.column)
  end

  def group_by(column : ColumnName)
    @groups << column
    self
  end

  def group_sql
    if grouped?
      "GROUP BY " + groups.join(", ")
    end
  end

  def groups
    @groups
  end

  def grouped?
    !@groups.empty?
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

  def selects
    @selections
      .split(", ")
      .map(&.split('.').last)
  end

  def select_direct(selection : Array(ColumnName))
    @selections = selection.join(", ")
    self
  end

  def select(selection : Array(ColumnName))
    @selections = selection.join(", ") { |column| "#{@table}.#{column}" }
    self
  end

  def select(@selections : String)
    self
  end

  def ordered?
    !@orders.empty?
  end

  def ordered_randomly?
    ordered? && @orders.first.is_a?(Avram::OrderByRandom)
  end

  private def select_sql
    String.build do |sql|
      sql << "SELECT "
      sql << "DISTINCT " if distinct?
      sql << "ON (#{@distinct_on}) " if has_distinct_on?
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
    if join_clause.to != table && @joins.none? { |join| join.to == join_clause.to }
      @joins << join_clause
    end
    self
  end

  def joins
    @joins.uniq(&.to_sql)
  end

  private def joins_sql
    joins.join(" ", &.to_sql)
  end

  def where(where_clause : Avram::Where::Condition)
    @wheres << where_clause
    self
  end

  def or(&block : Avram::QueryBuilder -> Avram::QueryBuilder)
    if @wheres.empty?
      raise Avram::InvalidQueryError.new("Cannot call `or` before calling a `where`")
    end

    @wheres.last.conjunction = Avram::Where::Conjunction::Or

    block.call(self)
  end

  # Clears the last conjunction
  # e.g. users.age = $1 AND -> users.age = $1
  def clear_conjunction
    @wheres.last.conjunction = Avram::Where::Conjunction::None unless @wheres.empty?
  end

  # Removes the last `Avram::Where` to be added
  def remove_last_where
    @wheres.pop
  end

  private def wheres_sql
    if !wheres.empty?
      statements = wheres.flat_map do |sql_clause|
        clause = sql_clause.prepare(->next_prepared_statement_placeholder)

        [clause, sql_clause.conjunction.to_s]
      end

      # Remove blank conjunctions
      statements.reject!(&.blank?)

      # Remove the last floating conjunction
      statements.pop

      "WHERE " + statements.join(" ")
    end
  end

  def wheres
    @wheres
  end

  private def prepared_statement_values
    wheres.compact_map do |sql_clause|
      sql_clause.value if sql_clause.is_a?(Avram::Where::ValueHoldingSqlClause)
    end
  end

  private def next_prepared_statement_placeholder
    @prepared_statement_placeholder += 1
    "$#{@prepared_statement_placeholder}"
  end

  private def delete_sql
    "DELETE FROM #{table}"
  end
end
