struct JSON::Any
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = JSON::Any
    extend Avram::Type

    def self.from_db!(value : JSON::Any)
      value
    end

    def self.parse(value : JSON::Any)
     Avram::Type::SuccessfulCast(JSON::Any).new value
    end

    def self.parse(value)
     Avram::Type::SuccessfulCast(JSON::Any).new JSON.parse(value.to_json)
    end

    def self.to_db(value)
      value.to_json
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
