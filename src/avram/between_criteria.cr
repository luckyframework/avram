module Avram::BetweenCriteria(T, V)
  macro included
    # WHERE @column >= `low_value` AND @column <= `high_value`
    def between(low_value : V, high_value : V)
      add_clause(Avram::Where::GreaterThanOrEqualTo.new(@column, V::Lucky.to_db!(low_value)))
      add_clause(Avram::Where::LessThanOrEqualTo.new(@column, V::Lucky.to_db!(high_value)))
    end
  end
end
