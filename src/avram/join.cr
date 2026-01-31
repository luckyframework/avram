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
      "#{Wordsmith::Inflector.singularize(@from.to_s)}_id"
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
end
