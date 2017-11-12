struct Int32
  module Lucky
    alias ColumnType = Int32
    include LuckyRecord::Type

    def self.from_db!(value : Int32)
      value
    end

    def self.parse(value : String)
      SuccessfulCast(Int32).new value.to_i
    rescue ArgumentError
      FailedCast.new
    end

    def self.parse(value : Int32)
      SuccessfulCast(Int32).new(value)
    end

    def self.to_db(value : Int32)
      value.to_s
    end

    class Criteria(T, V) < LuckyRecord::Criteria(T, V)
    end
  end
end
