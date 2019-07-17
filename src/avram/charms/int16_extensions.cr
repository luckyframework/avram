struct Int16
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int16
    include Avram::Type

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
    end

    def to_db(value : Int16)
      value.to_s
    end

    def to_db(values : Array(Int16))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
