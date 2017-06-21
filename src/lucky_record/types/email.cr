require "./string"

class LuckyRecord::EmailType < LuckyRecord::StringType
  def self.deserialize(value : String)
    value.downcase.strip
  end

  def self.cast(value : String)
    SuccessfulCast(String).new(value.downcase.strip)
  end
end
