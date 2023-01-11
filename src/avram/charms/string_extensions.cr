class String
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = String
    include Avram::Type

    def self.criteria(query : T, column) forall T
      Criteria(T, String).new(query, column)
    end

    def parse(value : String)
      SuccessfulCast(String).new(value)
    end

    def parse(values : Array(String))
      SuccessfulCast(Array(String)).new(values)
    end

    def to_db(value : String) : String
      value
    end

    def to_db(values : Array(String))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::IncludesCriteria(T, V)

      def like(value : String) : T
        add_clause(Avram::Where::Like.new(column, value))
      end

      def ilike(value : String) : T
        add_clause(Avram::Where::Ilike.new(column, value))
      end

      define_function_criteria(upper, V)
      define_function_criteria(lower, V)
      define_function_criteria(trim, String)
    end
  end
end
