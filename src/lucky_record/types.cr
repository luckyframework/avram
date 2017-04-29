class LuckyRecord::Types
  alias DbValue = Int32 | Int64 | String | Bool
  TYPE_MAPPINGS = {} of String => DbValue

  macro register(type, base_type)
    {% TYPE_MAPPINGS[type.resolve] = base_type}
  end
end

abstract class LuckyRecord::Type
  def self.parse(value)
    value
  end

  def self.parse_string(value : Nil)
    SuccessfulCast(Nil).new(nil)
  end

  def self.parse_string(value)
    SuccessfulCast(String).new(value)
  end

  def self.to_db_string(value : Nil)
    nil
  end

  def self.to_db_string(value : String)
    value
  end

  class SuccessfulCast(T)
    getter :value
    def initialize(@value : T)
    end
  end

  class FailedCast
  end
end

class LuckyRecord::StringType < LuckyRecord::Type
  LuckyRecord::Types.register LuckyRecord::StringType, String
end

class LuckyRecord::TimeType < LuckyRecord::Type
  LuckyRecord::Types.register LuckyRecord::TimeType, Time

  def self.parse_string(value : String)
    SuccessfulCast(Time).new Time.parse(value, pattern: "%FT%X%z")
  rescue Time::Format::Error
    FailedCast.new
  end

  def self.parse_string(value : Time)
    SuccessfulCast(Time).new value
  end

  def self.to_db_string(value : Time)
    value.to_s
  end
end

class LuckyRecord::Int32Type < LuckyRecord::Type
  LuckyRecord::Types.register LuckyRecord::Int32Type, Int32

  def self.parse_string(value : String)
    SuccessfulCast(Int32).new value.to_i
  rescue ArgumentError
    FailedCast.new
  end

  def self.to_db_string(value : Int32)
    value.to_s
  end
end

class LuckyRecord::EmailType < LuckyRecord::Type
  LuckyRecord::Types.register LuckyRecord::EmailType, String

  def self.parse(value)
    value.to_s.downcase.strip
  end
end
