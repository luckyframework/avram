class Avram::Criteria(T, V)
  property :rows, :column
  @negate_next_criteria : Bool

  def initialize(@rows : T, @column : Symbol | String)
    @negate_next_criteria = false
  end

  def desc_order(null_sorting : Avram::OrderBy::NullSorting = :default) : T
    rows.query.order_by(Avram::OrderBy.new(column, :desc, null_sorting))
    rows
  end

  def asc_order(null_sorting : Avram::OrderBy::NullSorting = :default) : T
    rows.query.order_by(Avram::OrderBy.new(column, :asc, null_sorting))
    rows
  end

  def eq(value) : T
    check_just_nil!(typeof(value))
    check_nilable!(value)
    perform_eq(value)
  end

  private def check_nilable!(_value : Nil)
    {% raise <<-ERROR

      The 'eq' method cannot compare values that may be 'nil'

      Try this...

        ▸ Use 'nilable_eq'. This method allows checking against nilable values
        ▸ Ensure the value is not nilable by wrapping it in an 'if' or using 'not_nil!'

      ERROR
    %}
  end

  private def check_nilable!(_value)
    # carry on
  end

  private def check_just_nil!(_type_of_value : Nil.class)
    {% raise <<-ERROR

      To check if a column is 'nil' use these methods instead...

        ▸ 'is_nil'
        ▸ 'is_not_nil'

      ERROR
    %}
  end

  private def check_just_nil!(_type_of_value)
    # carry on
  end

  private def perform_eq(value) : T
    add_clause(Avram::Where::Equal.new(column, V::Lucky.to_db!(value)))
  end

  def nilable_eq(value) : T
    check_just_nil!(typeof(value))

    if value.nil?
      is_nil
    else
      perform_eq(value)
    end
  end

  def is_nil : T
    add_clause(Avram::Where::Null.new(column))
  end

  def is_not_nil : T
    not()
    is_nil
  end

  def not : Avram::Criteria
    @negate_next_criteria = true
    self
  end

  def gt(value) : T
    add_clause(Avram::Where::GreaterThan.new(column, V::Lucky.to_db!(value)))
  end

  def gte(value) : T
    add_clause(Avram::Where::GreaterThanOrEqualTo.new(column, V::Lucky.to_db!(value)))
  end

  def lt(value) : T
    add_clause(Avram::Where::LessThan.new(column, V::Lucky.to_db!(value)))
  end

  def lte(value) : T
    add_clause(Avram::Where::LessThanOrEqualTo.new(column, V::Lucky.to_db!(value)))
  end

  def select_min : V
    rows.query.select_min(column)
    rows.exec_scalar.as(V)
  end

  def select_max : V
    rows.query.select_max(column)
    rows.exec_scalar.as(V)
  end

  def select_average : Float
    rows.query.select_average(column)
    rows.exec_scalar.as(PG::Numeric).to_f
  end

  def select_sum : Int64
    rows.query.select_sum(column)
    rows.exec_scalar.as(Int64)
  end

  def in(values) : T
    values = values.map { |value| V::Lucky.to_db!(value) }
    add_clause(Avram::Where::In.new(column, values))
  end

  # :nodoc:
  def __distinct_on : Avram::QueryBuilder
    rows.query.distinct_on(column)
  end

  private def add_clause(sql_clause) : T
    sql_clause = build_sql_clause(sql_clause)
    rows.query.where(sql_clause)
    rows
  end

  private def build_sql_clause(sql_clause : Avram::Where::SqlClause) : Avram::Where::SqlClause
    if @negate_next_criteria
      sql_clause.negated
    else
      sql_clause
    end
  end
end
