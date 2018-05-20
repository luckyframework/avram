struct Float64
  module Lucky
    alias ColumnType = Float64
    include LuckyRecord::Type

    def self.from_db!(value : Float64)
      value
    end

    def self.from_db!(value : PG::Numeric)
      value.to_f
    end

    def self.parse(value : Float64)
      SuccessfulCast(Float64).new(value)
    end

    def self.parse(value : String)
      SuccessfulCast(Float64).new value.to_f64
    rescue ArgumentError
      FailedCast.new
    end

    def self.parse(value : Int32)
      SuccessfulCast(Float64).new value.to_f64
    end

    def self.parse(value : Int64)
      SuccessfulCast(Float64).new value.to_f64
    end

    def self.to_db(value : Float64)
      value.to_s
    end

    class Criteria(T, V) < LuckyRecord::Criteria(T, V)
    end
  end
end
