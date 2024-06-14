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
      failure_reasons = casts.select(FailedCast)
        .map(&.reason)
        .join("\n")
      FailedCast.new(failure_reasons)
    end
  end

  def parse!(value)
    parse(value).value
  end

  def to_db(value : Nil)
    nil
  end

  def to_db!(value)
    parsed_value = parse!(value)
    to_db(parsed_value)
  end

  class SuccessfulCast(T)
    def initialize(@value : T)
    end

    def value : T
      @value
    end
  end

  class FailedCast
    getter reason

    def initialize(@reason : String?)
    end

    def value
      raise FailedCastError.new(reason || "Failed to cast value")
    end
  end
end
