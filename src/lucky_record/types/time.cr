class LuckyRecord::TimeType < LuckyRecord::Type
  alias BaseType = Time

  def self.cast(value : String)
    SuccessfulCast(Time).new Time.parse(value, pattern: "%FT%X%z")
  rescue Time::Format::Error
    FailedCast.new
  end

  def self.cast(value : Time)
    SuccessfulCast(Time).new value
  end

  def self.serialize(value : Time)
    value.to_s
  end
end
