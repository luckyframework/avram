require "./string"

class LuckyRecord::EmailType < LuckyRecord::StringType
  def self.cast(value : String)
    SuccessfulCast(String).new(value.downcase.strip)
  end

  def self.serialize(value : String)
    value.downcase.strip
  end
end
