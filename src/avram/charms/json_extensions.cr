module JSON::Serializable
  macro included
    def self.adapter
      Lucky(self)
    end
  end

  module Lucky(T)
    include Avram::Type

    def self.criteria(query : R, column) forall R
      Criteria(R, T).new(query, column)
    end

    def from_db!(value)
      value
    end

    def parse(value : JSON::Serializable)
      SuccessfulCast(JSON::Serializable).new value
    end

    def parse(value)
      SuccessfulCast(JSON::Serializable).new T.from_json(value)
    end

    def to_db(value) : String
      value.to_json
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end

struct JSON::Any
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = JSON::Any
    include Avram::Type

    def self.criteria(query : T, column) forall T
      Criteria(T, JSON::Any).new(query, column)
    end

    def from_db!(value : JSON::Any)
      value
    end

    def parse(value : JSON::Any)
      SuccessfulCast(JSON::Any).new value
    end

    def parse(value : String)
      value = begin
        JSON.parse(value)
      rescue JSON::ParseException
        JSON.parse(value.to_json)
      end
      SuccessfulCast(JSON::Any).new value
    end

    def parse(value : Nil)
      SuccessfulCast(Nil).new nil
    end

    def parse(value)
      SuccessfulCast(JSON::Any).new JSON.parse(value.to_json)
    end

    def to_db(value)
      value.to_json
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
