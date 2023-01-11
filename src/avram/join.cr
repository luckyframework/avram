require "wordsmith"

module Avram::Join
  abstract class SqlClause
    getter :from, :to, :from_column, :to_column

    def initialize(
      @from : TableName,
      @to : TableName,
      @primary_key : Symbol? = nil,
      @foreign_key : Symbol? = nil,
      @comparison : String? = "=",
      @using : Array(Symbol) = [] of Symbol
    )
    end

    abstract def join_type : String

    def to_sql : String
      if !@using.empty?
        %(#{join_type} JOIN #{@to} USING (#{@using.join(", ")}))
      else
        "#{join_type} JOIN #{@to} ON #{from_column} #{@comparison} #{to_column}"
      end
    end

    def from_column : String
      "#{@from}.#{@primary_key || "id"}"
    end

    def to_column : String
      "#{@to}.#{@foreign_key || default_foreign_key}"
    end

    def default_foreign_key : String
      Wordsmith::Inflector.singularize(@from) + "_id"
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
