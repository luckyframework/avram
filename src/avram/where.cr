module Avram::Where
  abstract class SqlClause
    getter :column
    getter :value

    def initialize(@column : Symbol | String, @value : String | Array(String) | Array(Int32))
    end

    abstract def operator : String
    abstract def negated : SqlClause

    def prepare(prepared_statement_placeholder : String)
      "#{column} #{operator} #{prepared_statement_placeholder}"
    end
  end

  abstract class NullSqlClause < SqlClause
    @value = "NULL"

    def initialize(@column : Symbol | String)
    end

    def prepare
      "#{column} #{operator} #{@value}"
    end
  end


  class Null < NullSqlClause
    def operator
      "IS"
    end

    def negated : NotNull
      NotNull.new(@column)
    end
  end

  class NotNull < NullSqlClause
    def operator
      "IS NOT"
    end

    def negated : Null
      Null.new(@column)
    end
  end

  class Equal < SqlClause
    def operator
      "="
    end

    def negated : NotEqual
      NotEqual.new(@column, @value)
    end
  end

  class NotEqual < SqlClause
    def operator
      "!="
    end

    def negated : Equal
      Equal.new(@column, @value)
    end
  end

  class GreaterThan < SqlClause
    def operator
      ">"
    end

    def negated : LessThanOrEqualTo
      LessThanOrEqualTo.new(@column, @value)
    end
  end

  class GreaterThanOrEqualTo < SqlClause
    def operator
      ">="
    end

    def negated : LessThan
      LessThan.new(@column, @value)
    end
  end

  class LessThan < SqlClause
    def operator
      "<"
    end

    def negated : GreaterThanOrEqualTo
      GreaterThanOrEqualTo.new(@column, @value)
    end
  end

  class LessThanOrEqualTo < SqlClause
    def operator
      "<="
    end

    def negated : GreaterThan
      GreaterThan.new(@column, @value)
    end
  end

  class Like < SqlClause
    def operator
      "LIKE"
    end

    def negated : NotLike
      NotLike.new(@column, @value)
    end
  end

  class Ilike < SqlClause
    def operator
      "ILIKE"
    end

    def negated : NotIlike
      NotIlike.new(@column, @value)
    end
  end

  class NotLike < SqlClause
    def operator
      "NOT LIKE"
    end

    def negated : Like
      Like.new(@column, @value)
    end
  end

  class NotIlike < SqlClause
    def operator
      "NOT ILIKE"
    end

    def negated : Ilike
      Ilike.new(@column, @value)
    end
  end

  class In < SqlClause
    def operator
      "= ANY"
    end

    def negated : NotIn
      NotIn.new(@column, @value)
    end

    def prepare(prepared_statement_placeholder : String)
      "#{column} #{operator} (#{prepared_statement_placeholder})"
    end
  end

  class NotIn < SqlClause
    def operator
      "!= ALL"
    end

    def negated : In
      In.new(@column, @value)
    end

    def prepare(prepared_statement_placeholder : String)
      "#{column} #{operator} (#{prepared_statement_placeholder})"
    end
  end

  class Raw
    @clause : String

    def initialize(statement : String, *bind_vars)
      ensure_enough_bind_variables_for!(statement, *bind_vars)
      @clause = build_clause(statement, *bind_vars)
    end

    def to_sql
      @clause
    end

    private def ensure_enough_bind_variables_for!(statement, *bind_vars)
      bindings = statement.chars.select(&.== '?')
      if bindings.size != bind_vars.size
        raise "wrong number of bind variables (#{bind_vars.size} for #{bindings.size}) in #{statement}"
      end
    end

    private def build_clause(statement, *bind_vars)
      bind_vars.each do |arg|
        if arg.is_a?(String) || arg.is_a?(Slice(UInt8))
          escaped = PG::EscapeHelper.escape_literal(arg)
        else
          escaped = arg
        end
        statement = statement.sub('?', escaped)
      end
      statement
    end
  end
end
