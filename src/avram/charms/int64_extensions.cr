struct Int64
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int64
    include Avram::Type

    def self.criteria(query : T, column) forall T
      Criteria(T, Int64).new(query, column)
    end

    def from_db!(value : Int64)
      value
    end

    def parse(value : Int64)
      SuccessfulCast(Int64).new(value)
    end

    def parse(values : Array(Int64))
      SuccessfulCast(Array(Int64)).new values
    end

    def parse(value : String)
      SuccessfulCast(Int64).new value.to_i64
    rescue ArgumentError
      FailedCast.new
    end

    def parse(value : Int32)
      SuccessfulCast(Int64).new value.to_i64
    end

    def to_db(value : Int64)
      value.to_s
    end

    def to_db(values : Array(Int64))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)

      def select_sum : Int64?
        if sum = super
          sum.as(PG::Numeric).to_f.to_i64
        end
      end

      def select_sum! : Int64
        select_sum || 0_i64
      end
    end
  end
end
