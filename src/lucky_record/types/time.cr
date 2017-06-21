class LuckyRecord::TimeType < LuckyRecord::Type
  alias BaseType = Time

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
