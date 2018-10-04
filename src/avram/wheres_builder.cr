class Avram::WheresBuilder
  {% begin %}
  alias PreparedStatementValue = Union(
    {% for possible_type in Avram::Migrator::ColumnDefaultHelpers::ColumnDefaultType.union_types %}
      {{ possible_type }}, Array({{ possible_type }}),
    {% end %}
    )
  {% end %}

  @wheres = [] of Avram::Where::SqlClause | Avram::Where::Raw | Avram::WheresBuilder
  @wheres_sql : String?
  property conjunction : Avram::Where::Conjunction = Avram::Where::Conjunction::And

  def initialize(@prepared_statement_generator : Avram::PreparedStatementGenerator)
  end

  def where(where_clause : Avram::Where::SqlClause | Avram::Where::Raw)
    @wheres << where_clause
    self
  end

  def or(&block : Avram::WheresBuilder -> Avram::WheresBuilder)
    if @wheres.empty?
      raise InvalidQueryError.new "Cannot call `or` on a query without any conditions."
    else
      @wheres.last.conjunction = Avram::Where::Conjunction::Or
      nested_builder = self.class.new(@prepared_statement_generator)
      yield nested_builder
      @wheres << nested_builder
      self
    end
  end

  def to_sql
    if j = joined
      @wheres_sql ||= "WHERE " + j
    else
      ""
    end
  end

  def prepared_statement_values
    prepped_values = [] of PreparedStatementValue
    @wheres.uniq.each do |sql_clause|
      if sql_clause.responds_to?(:prepared_statement_values)
        prepped_values += sql_clause.prepared_statement_values
      elsif sql_clause.responds_to?(:value)
        prepped_values << sql_clause.value
      end
    end
    prepped_values
  end

  protected def prepare
    "(#{joined})"
  end

  private def joined
    if @wheres.any?
      statements = @wheres.flat_map do |where_clause|
        where_clause_sql =
          case where_clause
          when Avram::Where::Raw
            where_clause.to_sql
          when Avram::Where::NullSqlClause, Avram::WheresBuilder
            where_clause.prepare
          else
            where_clause.prepare(@prepared_statement_generator)
          end
        [where_clause_sql, where_clause.conjunction.to_s]
      end

      # Will always have a trailing conjunction
      statements.pop

      statements.join(" ")
    end
  end
end
