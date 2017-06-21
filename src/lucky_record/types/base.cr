abstract class LuckyRecord::Type
  def self.deserialize(value)
    cast!(value)
  end

  def self.cast(value : Nil)
    SuccessfulCast(Nil).new(nil)
  end

  def self.cast(value : String)
    SuccessfulCast(String).new(value)
  end

  def self.cast!(value)
    cast(value).as(SuccessfulCast).value
  end

  def self.serialize(value : Nil)
    nil
  end

  def self.serialize(value : String)
    value
  end

  def self.cast_and_serialize(value)
    casted_value = cast!(value)
    serialize(casted_value)
  end

  class SuccessfulCast(T)
    getter :value

    def initialize(@value : T)
    end
  end

  class FailedCast
  end
end
