module Avram::BetweenCriteria(T, V)
  macro included
    # WHERE @column >= `low_value` AND @column <= `high_value`
    def between(low_value : V, high_value : V)
      add_clauses([
        Avram::Where::GreaterThanOrEqualTo.new(@column, V.to_db!(low_value)),
        Avram::Where::LessThanOrEqualTo.new(@column, V.to_db!(high_value))
      ])
    end
  end
end
