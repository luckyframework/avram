module Avram::IncludesCriteria(T, V)
  macro included
    # WHERE `value` = ANY(column)
    def includes(value) : T
      value = V.adapter.to_db!(value)
      add_clause(Avram::Where::Includes.new(column, value))
    end

    # TODO: Figure out how we can ensure this method
    # is only called on array columns at compile-time.
    private def check_using_array!(_value : Array.class)
    end

    private def check_using_array!(_value)
      \{% raise <<-ERROR

      The 'includes' query method can only compare a value to an array column.

      Try this...

        ▸ Ensure you're calling array_column.includes(value).
        ▸ Maybe you meant to use column.in(array_value)?
      ERROR
      %}
    end
  end
end
