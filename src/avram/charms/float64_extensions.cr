struct Float64
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Float64
    include Avram::Type(Float64)

    def from_db!(value : Float64)
      value
    end

    def from_db!(value : PG::Numeric)
      value.to_f
    end

    def parse(value : Float64)
      value
    end

    def parse(values : Array(Float64))
      values
    end

    def parse(value : PG::Numeric)
      value.to_f
    end

    def parse(value : String)
      value.to_f64
    rescue ArgumentError
      failed_cast
    end

    def parse(value : Int32)
      value.to_f64
    end

    def parse(value : Int64)
      value.to_f64
    end

    def to_db(value : Float64)
      value.to_s
    end

    def to_db(values : Array(Float64))
      PQ::Param.encode_array(values)
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
