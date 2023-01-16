struct Int16
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int16
    include Avram::Type

    def self.criteria(query : T, column) forall T
      Criteria(T, Int16).new(query, column)
    end

    def from_db!(value : Int16)
      value
    end

    def parse(value : Int16)
      SuccessfulCast(Int16).new(value)
    end

    def parse(values : Array(Int16))
      SuccessfulCast(Array(Int16)).new values
    end

    def parse(value : String)
      SuccessfulCast(Int16).new value.to_i16
    rescue ArgumentError
      FailedCast.new
    end

    def parse(value : Int32)
      SuccessfulCast(Int16).new value.to_i16
    rescue OverflowError
      FailedCast.new
    end

    def to_db(value : Int16) : String
      value.to_s
    end

    def to_db(values : Array(Int16))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)

      def select_sum : Int64?
        case sum = super
        when PG::Numeric
          sum.to_f.to_i64
        when Int
          sum.to_i64
        end
      end

      def select_sum! : Int64
        select_sum || 0_i64
      end
    end
  end
end
