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

  module Lucky
    alias ColumnType = Bool

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
