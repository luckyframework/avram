module Avram::Where
  enum Conjunction
    And
    Or
    None

    def to_s
      case self
      when .and?
        "AND"
      when .or?
        "OR"
      else
        ""
      end
    end
  end

  abstract class Condition
    property conjunction : Conjunction = Conjunction::And

    abstract def prepare(placeholder_supplier : Proc(String)) : String

    def clone
      self
    end
  end

  class PrecedenceStart < Condition
    def initialize
      @conjunction = Avram::Where::Conjunction::None
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "("
    end
  end

  class PrecedenceEnd < Condition
    def prepare(placeholder_supplier : Proc(String)) : String
      ")"
    end
  end

  abstract class SqlClause < Condition
    getter column : Symbol | String

    def initialize(@column)
    end

    abstract def operator : String
    abstract def negated : SqlClause

    def prepare(placeholder_supplier : Proc(String)) : String
      "#{column} #{operator} #{placeholder_supplier.call}"
    end
  end

  abstract class ValueHoldingSqlClause < SqlClause
    getter value : String | Array(String) | Array(Int32)

    def initialize(@column, @value)
    end
  end

  abstract class NullSqlClause < SqlClause
    def prepare(_placeholder_supplier : Proc(String)) : String
      "#{column} #{operator} NULL"
    end
  end

  class Null < NullSqlClause
    def operator : String
      "IS"
    end

    def negated : NotNull
      NotNull.new(column)
    end
  end

  class NotNull < NullSqlClause
    def operator : String
      "IS NOT"
    end

    def negated : Null
      Null.new(column)
    end
  end

  class Equal < ValueHoldingSqlClause
    def operator : String
      "="
    end

    def negated : NotEqual
      NotEqual.new(column, value)
    end
  end

  class NotEqual < ValueHoldingSqlClause
    def operator : String
      "!="
    end

    def negated : Equal
      Equal.new(column, value)
    end
  end

  class GreaterThan < ValueHoldingSqlClause
    def operator : String
      ">"
    end

    def negated : LessThanOrEqualTo
      LessThanOrEqualTo.new(column, value)
    end
  end

  class GreaterThanOrEqualTo < ValueHoldingSqlClause
    def operator : String
      ">="
    end

    def negated : LessThan
      LessThan.new(column, value)
    end
  end

  class LessThan < ValueHoldingSqlClause
    def operator : String
      "<"
    end

    def negated : GreaterThanOrEqualTo
      GreaterThanOrEqualTo.new(column, value)
    end
  end

  class LessThanOrEqualTo < ValueHoldingSqlClause
    def operator : String
      "<="
    end

    def negated : GreaterThan
      GreaterThan.new(column, value)
    end
  end

  class Like < ValueHoldingSqlClause
    def operator : String
      "LIKE"
    end

    def negated : NotLike
      NotLike.new(column, value)
    end
  end

  class Ilike < ValueHoldingSqlClause
    def operator : String
      "ILIKE"
    end

    def negated : NotIlike
      NotIlike.new(column, value)
    end
  end

  class NotLike < ValueHoldingSqlClause
    def operator : String
      "NOT LIKE"
    end

    def negated : Like
      Like.new(column, value)
    end
  end

  class NotIlike < ValueHoldingSqlClause
    def operator : String
      "NOT ILIKE"
    end

    def negated : Ilike
      Ilike.new(column, value)
    end
  end

  class In < ValueHoldingSqlClause
    def operator : String
      "= ANY"
    end

    def negated : NotIn
      NotIn.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "#{column} #{operator} (#{placeholder_supplier.call})"
    end
  end

  class NotIn < ValueHoldingSqlClause
    def operator : String
      "!= ALL"
    end

    def negated : In
      In.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "#{column} #{operator} (#{placeholder_supplier.call})"
    end
  end

  class Any < ValueHoldingSqlClause
    def operator : String
      "&&"
    end

    def negated : NotAny
      NotAny.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "#{column} #{operator} (#{placeholder_supplier.call})"
    end
  end

  class NotAny < ValueHoldingSqlClause
    def operator : String
      "&&"
    end

    def negated : Any
      Any.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "NOT(#{column} #{operator} (#{placeholder_supplier.call}))"
    end
  end

  class Includes < ValueHoldingSqlClause
    def operator : String
      "= ANY"
    end

    def negated : Excludes
      Excludes.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "#{placeholder_supplier.call} #{operator} (#{column})"
    end
  end

  class Excludes < ValueHoldingSqlClause
    def operator : String
      "!= ALL"
    end

    def negated : Includes
      Includes.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "#{placeholder_supplier.call} #{operator} (#{column})"
    end
  end

  class JsonbHasKey < ValueHoldingSqlClause
    def operator : String
      "?"
    end

    def negated : NotJsonbHasKey
      NotJsonbHasKey.new(column, value)
    end
  end

  class NotJsonbHasKey < ValueHoldingSqlClause
    def operator : String
      "?"
    end

    def negated : JsonbHasKey
      JsonbHasKey.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "NOT(#{column} #{operator} #{placeholder_supplier.call})"
    end
  end

  class JsonbHasAnyKeys < ValueHoldingSqlClause
    def operator : String
      "?|"
    end

    def negated : NotJsonbHasAnyKeys
      NotJsonbHasAnyKeys.new(column, value)
    end
  end

  class NotJsonbHasAnyKeys < ValueHoldingSqlClause
    def operator : String
      "?|"
    end

    def negated : JsonbHasAnyKeys
      JsonbHasAnyKeys.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "NOT(#{column} #{operator} #{placeholder_supplier.call})"
    end
  end

  class JsonbHasAllKeys < ValueHoldingSqlClause
    def operator : String
      "?&"
    end

    def negated : NotJsonbHasAllKeys
      NotJsonbHasAllKeys.new(column, value)
    end
  end

  class NotJsonbHasAllKeys < ValueHoldingSqlClause
    def operator : String
      "?&"
    end

    def negated : JsonbHasAllKeys
      JsonbHasAllKeys.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "NOT(#{column} #{operator} #{placeholder_supplier.call})"
    end
  end

  class JsonbIncludes < ValueHoldingSqlClause
    def operator : String
      "@>"
    end

    def negated : JsonbExcludes
      JsonbExcludes.new(column, value)
    end
  end

  class JsonbExcludes < ValueHoldingSqlClause
    def operator : String
      "@>"
    end

    def negated : JsonbIncludes
      JsonbIncludes.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "NOT(#{column} #{operator} #{placeholder_supplier.call})"
    end
  end

  class JsonbIn < ValueHoldingSqlClause
    def operator : String
      "<@"
    end

    def negated : JsonbNotIn
      JsonbNotIn.new(column, value)
    end
  end

  class JsonbNotIn < ValueHoldingSqlClause
    def operator : String
      "<@"
    end

    def negated : JsonbIn
      JsonbIn.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "NOT(#{column} #{operator} #{placeholder_supplier.call})"
    end
  end

  class TsMatch < ValueHoldingSqlClause
    def operator : String
      "@@"
    end

    def negated : TsNotMatch
      TsNotMatch.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "#{column} #{operator} TO_TSQUERY(#{placeholder_supplier.call})"
    end
  end

  class TsNotMatch < ValueHoldingSqlClause
    def operator : String
      "@@"
    end

    def negated : TsMatch
      TsMatch.new(column, value)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      "NOT(#{column} #{operator} TO_TSQUERY(#{placeholder_supplier.call}))"
    end
  end

  class Raw < Condition
    @clause : String

    def self.new(statement : String, *bind_vars)
      new(statement, args: bind_vars.to_a)
    end

    def initialize(statement : String, *, args bind_vars : Array)
      ensure_enough_bind_variables_for!(statement, bind_vars)
      @clause = build_clause(statement, bind_vars)
    end

    def prepare(placeholder_supplier : Proc(String)) : String
      @clause
    end

    private def ensure_enough_bind_variables_for!(statement, bind_vars)
      bindings = statement.chars.select!(&.== '?')
      if bindings.size != bind_vars.size
        raise "wrong number of bind variables (#{bind_vars.size} for #{bindings.size}) in #{statement}"
      end
    end

    private def build_clause(statement, bind_vars)
      bind_vars.each do |arg|
        encoded_arg = prepare_for_execution(arg)
        statement = statement.sub('?', encoded_arg)
      end
      statement
    end

    private def prepare_for_execution(value)
      if value.is_a?(Array)
        "'#{PQ::Param.encode_array(value)}'"
      else
        escape_if_needed(value)
      end
    end

    private def escape_if_needed(value)
      if value.is_a?(String) || value.is_a?(Slice(UInt8))
        PG::EscapeHelper.escape_literal(value)
      else
        value
      end
    end
  end
end
