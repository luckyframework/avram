struct Int32
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int32
    include Avram::Type

    def from_db!(value : Int32)
      value
    end

    def parse(value : String)
      SuccessfulCast(Int32).new value.to_i
    rescue ArgumentError
      FailedCast.new
    end

    def parse(value : Int32)
      SuccessfulCast(Int32).new(value)
    end

    def parse(values : Array(Int32))
      SuccessfulCast(Array(Int32)).new values
    end

    def to_db(value : Int32)
      value.to_s
    end

    def to_db(values : Array(Int32))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)
    end
  end
end
