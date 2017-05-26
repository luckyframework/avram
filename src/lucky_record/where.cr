module LuckyRecord::Where
  abstract class SqlClause
    getter :column, :value

    def initialize(@column : Symbol | String, @value : String)
    end

    abstract def operator : String

    def prepare(prepared_statement_placeholder : String)
      "#{column} #{operator} #{prepared_statement_placeholder}"
    end
  end

  class Equal < SqlClause
    def operator
      "="
    end
  end

  class NotEqual < SqlClause
    def operator
      "!="
    end
  end

  class GreaterThan < SqlClause
    def operator
      ">"
    end
  end

  class GreaterThanOrEqualTo < SqlClause
    def operator
      ">="
    end
  end

  class LessThan < SqlClause
    def operator
      "<"
    end
  end

  class LessThanOrEqualTo < SqlClause
    def operator
      "<="
    end
  end

  class Like < SqlClause
    def operator
      "LIKE"
    end
  end

  class Ilike < SqlClause
    def operator
      "ILIKE"
    end
  end
end
