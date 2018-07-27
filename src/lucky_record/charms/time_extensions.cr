struct Time
  module Lucky
    alias ColumnType = Time
    include LuckyRecord::Type

    def self.from_db!(value : Time)
      value
    end

    def self.parse(value : String)
      SuccessfulCast(Time).new Time.parse_iso8601(value).to_utc
    rescue Time::Format::Error
      FailedCast.new
    end

    def self.parse(value : Time)
      SuccessfulCast(Time).new value
    end

    def self.to_db(value : Time)
      value.to_s
    end

    class Criteria(T, V) < LuckyRecord::Criteria(T, V)
    end
  end
end
