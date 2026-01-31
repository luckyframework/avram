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
  @for_update : Bool = false

  def initialize(@table)
  end

  def to_sql : Array(Array(Int32) | Array(String) | String)
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

  def statement : String
    clone.statement!
  end

  def statement! : String
    join_sql [@delete ? delete_sql : select_sql] + sql_condition_clauses
  end

  def statement_for_update(params, return_columns returning : Bool = true)
    clone.statement_for_update!(params, returning)
  end

  # Creates the SQL for updating. If any joins are present, it
  # moves the WHERE clause to a subquery allowing for joins
  def statement_for_update!(params, return_columns returning : Bool = true)
    sql = Array(String?).new(14)

    sql << "UPDATE #{table}" << set_sql_clause(params)

    if joins_sql.presence
      sql << "WHERE EXISTS" << "(" << select_sql
      sql.concat(sql_condition_clauses)
      sql << ")"
    else
      sql.concat(sql_condition_clauses)
    end

    sql << "RETURNING #{@selections}" if returning

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
    end
  end

  private def set_sql_clause(params) : String
    "SET " + params.join(", ") do |key, _|
      "#{key} = #{next_prepared_statement_placeholder}"
    end
  end

  private def join_sql(clauses) : String
    clauses.reject do |clause|
      clause.nil? || clause.blank?
    end.join(" ")
  end

  def args : Array(String | Array(String) | Array(Int32))
    prepared_statement_values
  end

  private def sql_condition_clauses
    [joins_sql, wheres_sql, group_sql, order_sql, limit_sql, offset_sql, locking_sql]
  end

  def delete : self
    @delete = true
    self
  end

  def distinct : self
    @distinct = true
    self
  end

  def distinct_on(column : ColumnName) : self
    @distinct_on = column
    self
  end

  def distinct? : Bool
    @distinct || has_distinct_on?
  end

  def has_distinct_on? : Bool
    !!@distinct_on
  end

  def limit : Int32?
    @limit
  end

  def limit(@limit : Int32?) : self
    self
  end

  def offset : Int32?
    @offset
  end

  def offset(@offset : Int32?) : self
    self
  end

  def for_update : self
    @for_update = true
    self
  end

  def order_by(order : OrderByClause) : self
    reset_order if ordered_randomly?
    @orders << order
    self
  end

  def random_order : self
    reset_order
    @orders << Avram::OrderByRandom.new
    self
  end

  def reset_where(column : ColumnName) : self
    @wheres = @wheres.reject do |clause|
      clause.is_a?(Avram::Where::SqlClause) && clause.column.to_s == column.to_s
    end

    self
  end

  def reset_order : Array(Avram::OrderByClause)
    @orders = Array(Avram::OrderByClause).new
  end

  def reverse_order : self
    @orders = @orders.map(&.reversed).reverse! unless ordered_randomly?
    self
  end

  def order_sql : String?
    if ordered?
      "ORDER BY #{orders.join(", ", &.prepare)}"
    end
  end

  def orders : Array(Avram::OrderByClause)
    @orders.uniq!(&.column)
  end

  def group_by(column : ColumnName) : self
    @groups << column
    self
  end

  def group_sql : String?
    if grouped?
      "GROUP BY #{groups.join(", ")}"
    end
  end

  def groups : Array(ColumnName)
    @groups
  end

  def grouped? : Bool
    !@groups.empty?
  end

  def select_count : self
    add_aggregate "COUNT(*)"
  end

  def select_min(column : ColumnName) : self
    add_aggregate "MIN(#{column})"
  end

  def select_max(column : ColumnName) : self
    add_aggregate "MAX(#{column})"
  end

  def select_average(column : ColumnName) : self
    add_aggregate "AVG(#{column})"
  end

  def select_sum(column : ColumnName) : self
    add_aggregate "SUM(#{column})"
  end

  private def add_aggregate(sql : String) : self
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

  private def has_unsupported_clauses? : Bool
    !@limit.nil? || !@offset.nil?
  end

  def selects : Array(String)
    @selections
      .split(", ")
      .map(&.split('.').last)
  end

  def select_direct(selection : Array(ColumnName)) : self
    @selections = selection.join(", ")
    self
  end

  def select(selection : Array(ColumnName)) : self
    @selections = selection.join(", ") { |column| %("#{@table}"."#{column}") }
    self
  end

  def select(@selections : String) : self
    self
  end

  def ordered? : Bool
    !@orders.empty?
  end

  def ordered_randomly? : Bool
    ordered? && @orders.first.is_a?(Avram::OrderByRandom)
  end

  private def select_sql : String
    String.build do |sql|
      sql << "SELECT "
      sql << "DISTINCT " if distinct?
      sql << "ON (" << @distinct_on << ") " if has_distinct_on?
      sql << @selections
      sql << " FROM "
      sql << table
    end
  end

  private def limit_sql : String?
    if @limit
      "LIMIT #{@limit}"
    end
  end

  private def offset_sql : String?
    if @offset
      "OFFSET #{@offset}"
    end
  end

  def join(join_clause : Avram::Join::SqlClause) : self
    if join_clause.to != table && @joins.none? { |join| join.to == join_clause.to }
      @joins << join_clause
    end
    self
  end

  def joins : Array(Avram::Join::SqlClause)
    @joins.uniq(&.to_sql)
  end

  private def joins_sql : String
    joins.join(" ", &.to_sql)
  end

  def where(where_clause : Avram::Where::Condition) : self
    @wheres << where_clause
    self
  end

  def or(&block : Avram::QueryBuilder -> Avram::QueryBuilder) : self
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

  private def wheres_sql : String?
    if !wheres.empty?
      statements = wheres.flat_map do |sql_clause|
        clause = sql_clause.prepare(->next_prepared_statement_placeholder)

        [clause, sql_clause.conjunction.to_s]
      end

      # Remove blank conjunctions
      statements.reject!(&.blank?)

      # Remove the last floating conjunction
      statements.pop

      "WHERE #{statements.join(" ")}"
    end
  end

  def wheres : Array(Avram::Where::Condition)
    @wheres
  end

  private def prepared_statement_values : Array(String | Array(String) | Array(Int32))
    wheres.compact_map do |sql_clause|
      sql_clause.value if sql_clause.is_a?(Avram::Where::ValueHoldingSqlClause)
    end
  end

  private def next_prepared_statement_placeholder : String
    @prepared_statement_placeholder += 1
    "$#{@prepared_statement_placeholder}"
  end

  private def delete_sql : String
    "DELETE FROM #{table}"
  end

  private def locking_sql : String?
    if @for_update
      "FOR UPDATE"
    end
  end
end
