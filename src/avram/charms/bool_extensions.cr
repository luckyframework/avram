struct Bool
  extend Avram::Type

  def self.parse_attribute(value : String)
    if %w(true 1).includes? value
      Avram::Type::SuccessfulCast(Bool).new true
    elsif %w(false 0).includes? value
      Avram::Type::SuccessfulCast(Bool).new false
    else
      Avram::Type::FailedCast.new
    end
  end

  def self.parse_attribute(value : Bool)
    Avram::Type::SuccessfulCast(Bool).new value
  end

  def self.parse_attribute(values : Array(Bool))
    Avram::Type::SuccessfulCast(Array(Bool)).new values
  end

  def self.adapter
    self
  end

  module Lucky
    alias ColumnType = Bool

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
