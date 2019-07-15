struct Float64
  module Lucky
    alias ColumnType = Float64
    include Avram::Type

    def from_db!(value : Float64)
      value
    end

    def from_db!(value : PG::Numeric)
      value.to_f
    end

    def parse(value : Float64)
      SuccessfulCast(Float64).new(value)
    end

    def parse(values : Array(Float64))
      SuccessfulCast(Array(Float64)).new values
    end

    def parse(value : PG::Numeric)
      SuccessfulCast(Float64).new(value.to_f)
    end

    def parse(value : String)
      SuccessfulCast(Float64).new value.to_f64
    rescue ArgumentError
      FailedCast.new
    end

    def parse(values : Array(String))
      values = values.map {|value| parse(value).value }.as(Array(Float64))
      parse(values)
    end

    def parse(value : Int32)
      SuccessfulCast(Float64).new value.to_f64
    end

    def parse(value : Int64)
      SuccessfulCast(Float64).new value.to_f64
    end

    def to_db(value : Float64)
      value.to_s
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
