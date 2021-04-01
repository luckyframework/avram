module Avram::Type
  macro included
    extend self
  end

  def from_db!(value)
    parse!(value)
  end

  def parse(value : Nil)
    SuccessfulCast(Nil).new(nil)
  end

  def parse(values : Array(String))
    casts = values.map { |value| parse(value) }
    if casts.all?(SuccessfulCast)
      values = casts.map { |c| c.as(SuccessfulCast).value }
      parse(values)
    else
      FailedCast.new
    end
  end

  def parse!(value)
    parse(value).as(SuccessfulCast).value
  end

  def to_db(value : Nil)
    nil
  end

  def to_db!(value)
    parsed_value = parse!(value)
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
