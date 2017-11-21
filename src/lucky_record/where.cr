module LuckyRecord::Where
  abstract class SqlClause
    getter :column, :value

    def initialize(@column : Symbol | String, @value : String)
    end

    abstract def operator : String
    abstract def negated : SqlClause

    def prepare(prepared_statement_placeholder : String)
      "#{column} #{operator} #{prepared_statement_placeholder}"
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
end
