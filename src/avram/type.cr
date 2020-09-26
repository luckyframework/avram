module Avram::Type
  def from_db!(value)
    _parse_attribute!(value)
  end

  def _parse_attribute(value : Nil)
    Avram::Type::SuccessfulCast(Nil).new(nil)
  end

  def _parse_attribute(values : Array(String))
    casts = values.map { |value| _parse_attribute(value) }
    if casts.all?(&.is_a?(Avram::Type::SuccessfulCast))
      values = casts.map { |c| c.as(Avram::Type::SuccessfulCast).value }
      _parse_attribute(values)
    else
     Avram::Type::FailedCast.new
    end
  end

  def _parse_attribute!(value)
    _parse_attribute(value).as(Avram::Type::SuccessfulCast).value
  end

  def to_db(value : Nil)
    nil
  end

  def to_db!(value)
    parsed_value = _parse_attribute!(value)
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
