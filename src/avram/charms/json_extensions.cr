struct JSON::Any
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = JSON::Any
    include Avram::Type(JSON::Any)

    def from_db!(value : JSON::Any)
      value
    end

    def parse(value : JSON::Any)
      value
    end

    def parse(value)
      JSON.parse(value.to_json)
    end

    def to_db(value)
      value.to_json
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
