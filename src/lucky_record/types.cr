class LuckyRecord::Criteria(T)
  property :rows, :column

  def initialize(@rows : T, @column : Symbol)
  end

  def is(value)
    rows.query.where(LuckyRecord::Where::Equal.new(column, value.to_s))
    rows
  end

  def is_not(value)
    rows.query.where(LuckyRecord::Where::NotEqual.new(column, value.to_s))
    rows
  end

  def gt(value)
    rows.query.where(LuckyRecord::Where::GreaterThan.new(column, value.to_s))
    rows
  end

  def gte(value)
    rows.query.where(LuckyRecord::Where::GreaterThanOrEqualTo.new(column, value.to_s))
    rows
  end

  def lt(value)
    rows.query.where(LuckyRecord::Where::LessThan.new(column, value.to_s))
    rows
  end

  def lte(value)
    rows.query.where(LuckyRecord::Where::LessThanOrEqualTo.new(column, value.to_s))
    rows
  end
end

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

class LuckyRecord::StringType < LuckyRecord::Type
  alias BaseType = String
end

class LuckyRecord::StringType::Criteria(T) < LuckyRecord::Criteria(T)
end

class LuckyRecord::TimeType < LuckyRecord::Type
  alias BaseType = Time

  def self.parse_string(value : String)
    SuccessfulCast(Time).new Time.parse(value, pattern: "%FT%X%z")
  rescue Time::Format::Error
    FailedCast.new
  end

  def self.parse_string(value : Time)
    SuccessfulCast(Time).new value
  end

  def self.to_db_string(value : Time)
    value.to_s
  end
end

class LuckyRecord::Int32Type < LuckyRecord::Type
  alias BaseType = Int32

  def self.parse_string(value : String)
    SuccessfulCast(Int32).new value.to_i
  rescue ArgumentError
    FailedCast.new
  end

  def self.to_db_string(value : Int32)
    value.to_s
  end
end

class LuckyRecord::Int32Type::Criteria(T) < LuckyRecord::Criteria(T)
end

class LuckyRecord::EmailType < LuckyRecord::Type
  alias BaseType = String

  def self.parse(value)
    value.to_s.downcase.strip
  end
end

class LuckyRecord::EmailType::Criteria(T) < LuckyRecord::Criteria(T)
  @upper = false

  def upper
    @upper = true
    self
  end

  def is(value)
    rows.query.where(LuckyRecord::Where::Equal.new(column, value.to_s))
    rows
  end

  def column
    if @upper
      "UPPER(#{@column})"
    else
      @column
    end
  end
end
