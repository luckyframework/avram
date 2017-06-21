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
