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
    values = values.map do |value|
      parsed_result = parse(value)
      if parsed_result.is_a? Avram::Type::SuccessfulCast
        parsed_result.value
      else
        nil
      end
    end.compact.as(Array)
    parse(values)
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
  end
end
