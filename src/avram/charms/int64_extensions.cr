struct Int64
  module Lucky
    alias ColumnType = Int64
    include Avram::Type

    def self.from_db!(value : Int64)
      value
    end

    def self.parse(value : Int64)
      SuccessfulCast(Int64).new(value)
    end

    def self.parse(value : String)
      SuccessfulCast(Int64).new value.to_i64
    rescue ArgumentError
      FailedCast.new
    end

    def self.parse(value : Int32)
      SuccessfulCast(Int64).new value.to_i64
    end

    def self.to_db(value : Int64)
      value.to_s
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
