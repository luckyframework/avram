struct Int16
  module Lucky
    alias ColumnType = Int16
    include Avram::Type

    def self.from_db!(value : Int16)
      value
    end

    def self.parse(value : Int16)
      SuccessfulCast(Int16).new(value)
    end

    def self.parse(value : String)
      SuccessfulCast(Int16).new value.to_i16
    rescue ArgumentError
      FailedCast.new
    end

    def self.parse(value : Int32)
      SuccessfulCast(Int16).new value.to_i16
    end

    def self.to_db(value : Int16)
      value.to_s
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
