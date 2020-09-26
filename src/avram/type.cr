module Avram::Type
  def _from_db!(value)
    _parse_attribute!(value)
  end

  def _parse_attribute(value : Nil)
    Avram::Type::SuccessfulCast(Nil).new(nil)
  end

  def _parse_attribute(value : self)
    Avram::Type::SuccessfulCast(self).new(value)
  end

  def _parse_attribute(values : Array(self))
    Avram::Type::SuccessfulCast(Array(self)).new(values)
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

  def _to_db(value : Nil)
    nil
  end

  def _to_db(value : self)
    value.to_s
  end

  def _to_db!(value : Array(T)) forall T
    Array._to_db(_parse_attribute!(value))
  end

  def _to_db!(value)
    _to_db(_parse_attribute!(value))
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
