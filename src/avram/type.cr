module Avram::Type(T)
  macro included
    extend self
  end

  def from_db!(value)
    parse!(value)
  end

  def parse(value : Nil)
    nil
  end

  def parse(values : Array(String))
    casts = values.map { |value| parse(value) }
    if casts.none?(&.is_a?(FailedCast))
      values = casts.map { |c| c.as(T) }
      parse(values)
    else
      failed_cast
    end
  end

  def parse!(value)
    parse(value)
  end

  def to_db(value : Nil)
    nil
  end

  def to_db!(value)
    parsed_value = parse!(value)
    to_db(parsed_value)
  end

  def failed_cast
    FailedCast.new
  end

  class FailedCast
    def value
      nil
    end
  end
end
