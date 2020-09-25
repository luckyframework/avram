struct JSON::Any
  extend Avram::Type

  def self.parse_attribute(value)
    Avram::Type::SuccessfulCast(JSON::Any).new JSON.parse(value.to_json)
  end

  def self.to_db(value)
    value.to_json
  end

  module Lucky
    alias ColumnType = JSON::Any

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
