struct UUID
  extend Avram::Type

  def self._parse_attribute(value : String)
    Avram::Type::SuccessfulCast(UUID).new(UUID.new(value))
  rescue
    Avram::Type::FailedCast.new
  end

  def self._to_db(value : UUID)
    value.to_s
  end

  module Lucky
    alias ColumnType = String

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
