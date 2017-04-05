module LuckyRecord::Where
  abstract class SqlClause
    private getter :column, :value

    def initialize(@column : Symbol, @value : String)
    end

    abstract def to_sql : String
  end

  class Equal < SqlClause
    def to_sql
      "#{column} = #{value}"
    end
  end

  class GreaterThan < SqlClause
    def to_sql
      "#{column} > #{value}"
    end
  end

  class GreaterThanOrEqualTo < SqlClause
    def to_sql
      "#{column} >= #{value}"
    end
  end

  class LessThan < SqlClause
    def to_sql
      "#{column} < #{value}"
    end
  end

  class LessThanOrEqualTo < SqlClause
    def to_sql
      "#{column} <= #{value}"
    end
  end
end
