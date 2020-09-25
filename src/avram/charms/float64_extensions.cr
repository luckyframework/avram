struct Float64
  def self.adapter
    Lucky
  end

  module LuckyConverter
    def self.from_rs(rs)
      rs.read(PG::Numeric?).try &.to_f
    end
  end

  module Lucky
    alias ColumnType = Float64
    include Avram::Type

    def parse(value : Float64)
      SuccessfulCast(Float64).new(value)
    end

    def parse(values : Array(Float64))
      SuccessfulCast(Array(Float64)).new values
    end

    def parse(value : PG::Numeric)
      SuccessfulCast(Float64).new(value.to_f)
    end

    def parse(values : Array(PG::Numeric))
      SuccessfulCast(Array(Float64)).new values.map(&.to_f)
    end

    def parse(value : String)
      SuccessfulCast(Float64).new value.to_f64
    rescue ArgumentError
      FailedCast.new
    end

    def parse(value : Int32)
      SuccessfulCast(Float64).new value.to_f64
    end

    def parse(value : Int64)
      SuccessfulCast(Float64).new value.to_f64
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)

      def select_sum : Float64?
        if sum = super
          sum.as(PG::Numeric).to_f
        end
      end

      def select_sum! : Float64
        select_sum || 0_f64
      end
    end
  end
end
