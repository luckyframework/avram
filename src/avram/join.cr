require "wordsmith"

module Avram::Join
  abstract class SqlClause
    getter from : TableName

    @using : String

    def initialize(
      @from : TableName,
      @to : TableName,
      @primary_key : Symbol? = nil,
      @foreign_key : Symbol? = nil,
      @comparison : String? = "=",
      using : Array(Symbol) = [] of Symbol,
      @alias_to : TableName? = nil,
    )
      @using = using.join(", ") { |col| %("#{col}") }
    end

    abstract def join_type : String

    def to_sql : String
      String.build do |io|
        io << join_type << " JOIN "
        @to.to_s(io)
        if @alias_to
          io << " AS " << @alias_to
        end
        if @using.presence
          io << " USING (" << @using << ')'
        else
          io << " ON " << from_column << ' ' << @comparison << ' ' << to_column
        end
      end
    end

    def to : TableName
      @alias_to || @to
    end

    def from_column : String
      %("#{@from}"."#{@primary_key || "id"}")
    end

    def to_column : String
      %("#{to}"."#{@foreign_key || default_foreign_key}")
    end

    def default_foreign_key : String
      Wordsmith::Inflector.singularize(@from.to_s) + "_id"
    end

    def clone : self
      self
    end
  end

  class Inner < SqlClause
    def join_type : String
      "INNER"
    end
  end

  class Left < SqlClause
    def join_type : String
      "LEFT"
    end
  end

  class Right < SqlClause
    def join_type : String
      "RIGHT"
    end
  end

  class Full < SqlClause
    def join_type : String
      "FULL"
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

    def prepare(placeholder_supplier : Proc(String)) : String
      @clause
    end

    def to_sql : String
      @clause
    end

    def clone : self
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
