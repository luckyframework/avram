module Avram::Where
  abstract class SqlClause
    getter :column
    getter :value

    def initialize(@column : Symbol | String, @value : String | Array(String) | Array(Int32))
    end

    abstract def operator : String
    abstract def negated : SqlClause

    def prepare(placeholder_supplier : Proc(String))
      "#{column} #{operator} #{placeholder_supplier.call}"
    end

    def clone
      self
    end

    def ==(other : SqlClause)
      (prepare(->{"unusued"}) + value.to_s) == (other.prepare(->{"unused"}) + other.value.to_s)
    end

    def ==(other)
      false
    end
  end

  abstract class NullSqlClause < SqlClause
    @value = "NULL"

    def initialize(@column : Symbol | String)
    end

    def prepare(_placeholder_supplier : Proc(String))
      "#{column} #{operator} #{@value}"
    end
  end

  class Null < NullSqlClause
    def operator : String
      "IS"
    end

    def negated : NotNull
      NotNull.new(@column)
    end
  end

  class NotNull < NullSqlClause
    def operator : String
      "IS NOT"
    end

    def negated : Null
      Null.new(@column)
    end
  end

  class Equal < SqlClause
    def operator : String
      "="
    end

    def negated : NotEqual
      NotEqual.new(@column, @value)
    end
  end

  class NotEqual < SqlClause
    def operator : String
      "!="
    end

    def negated : Equal
      Equal.new(@column, @value)
    end
  end

  class GreaterThan < SqlClause
    def operator : String
      ">"
    end

    def negated : LessThanOrEqualTo
      LessThanOrEqualTo.new(@column, @value)
    end
  end

  class GreaterThanOrEqualTo < SqlClause
    def operator : String
      ">="
    end

    def negated : LessThan
      LessThan.new(@column, @value)
    end
  end

  class LessThan < SqlClause
    def operator : String
      "<"
    end

    def negated : GreaterThanOrEqualTo
      GreaterThanOrEqualTo.new(@column, @value)
    end
  end

  class LessThanOrEqualTo < SqlClause
    def operator : String
      "<="
    end

    def negated : GreaterThan
      GreaterThan.new(@column, @value)
    end
  end

  class Like < SqlClause
    def operator : String
      "LIKE"
    end

    def negated : NotLike
      NotLike.new(@column, @value)
    end
  end

  class Ilike < SqlClause
    def operator : String
      "ILIKE"
    end

    def negated : NotIlike
      NotIlike.new(@column, @value)
    end
  end

  class NotLike < SqlClause
    def operator : String
      "NOT LIKE"
    end

    def negated : Like
      Like.new(@column, @value)
    end
  end

  class NotIlike < SqlClause
    def operator : String
      "NOT ILIKE"
    end

    def negated : Ilike
      Ilike.new(@column, @value)
    end
  end

  class In < SqlClause
    def operator : String
      "= ANY"
    end

    def negated : NotIn
      NotIn.new(@column, @value)
    end

    def prepare(placeholder_supplier : Proc(String))
      "#{column} #{operator} (#{placeholder_supplier.call})"
    end
  end

  class NotIn < SqlClause
    def operator : String
      "!= ALL"
    end

    def negated : In
      In.new(@column, @value)
    end

    def prepare(placeholder_supplier : Proc(String))
      "#{column} #{operator} (#{placeholder_supplier.call})"
    end
  end

  class Raw
    @clause : String

    def self.new(statement : String, *bind_vars)
      new(statement, args: bind_vars.to_a)
    end

    def initialize(statement : String, *, args bind_vars : Array)
      ensure_enough_bind_variables_for!(statement, bind_vars)
      @clause = build_clause(statement, bind_vars)
    end

    def prepare(_placeholder_supplier : Proc(String))
      @clause
    end

    def clone
      self
    end

    private def ensure_enough_bind_variables_for!(statement, bind_vars)
      bindings = statement.chars.select(&.== '?')
      if bindings.size != bind_vars.size
        raise "wrong number of bind variables (#{bind_vars.size} for #{bindings.size}) in #{statement}"
      end
    end

    private def build_clause(statement, bind_vars)
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
