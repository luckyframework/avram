module Avram::Type
  def from_db!(value)
    parse!(value)
  end

  def parse(value : Nil)
    Avram::Type::SuccessfulCast(Nil).new(nil)
  end

  def parse(values : Array(String))
    casts = values.map { |value| parse(value) }
    if casts.all?(&.is_a?(Avram::Type::SuccessfulCast))
      values = casts.map { |c| c.as(Avram::Type::SuccessfulCast).value }
      parse(values)
    else
     Avram::Type::FailedCast.new
    end
  end

  def parse!(value)
    parse(value).as(Avram::Type::SuccessfulCast).value
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
