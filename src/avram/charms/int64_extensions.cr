struct Int64
  module Lucky
    alias ColumnType = Int64
    include Avram::Type

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

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
