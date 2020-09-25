module Avram::Type
  def adapter
    self
  end

  def parse_attribute(value : Nil)
    SuccessfulCast(Nil).new(nil)
  end

  def parse_attribute(value : self)
    SuccessfulCast(self).new(value)
  end

  def parse_attribute(values : Array(self))
    SuccessfulCast(Array(self)).new(values)
  end

  def parse_attribute(values : Array(String))
    casts = values.map { |value| parse_attribute(value) }
    if casts.all?(&.is_a?(SuccessfulCast))
      values = casts.map { |c| c.as(SuccessfulCast).value }
      parse_attribute(values)
    else
      FailedCast.new
    end
  end

  def parse_attribute!(value)
    parse_attribute(value).as(SuccessfulCast).value
  end

  def to_db(value : Nil)
    nil
  end

  def to_db(values : Array(T)) forall T
    PQ::Param.encode_array(values)
  end

  def to_db(value)
    value.to_s
  end

  def to_db!(value)
    parsed_value = parse_attribute!(value)
    to_db(parsed_value)
  end

  class SuccessfulCast(T)
    getter :value

    def initialize(@value : T)
    end
  end

  class FailedCast
    def value
      nil
    end
  end
end
