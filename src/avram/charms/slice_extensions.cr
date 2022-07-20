struct Slice(T)
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Bytes
    include Avram::Type

    def self.criteria(query : T, column) forall T
      Criteria(T, Bytes).new(query, column)
    end

    def from_db!(value : Bytes)
      value
    end

    def parse(value : Bytes)
      SuccessfulCast(Bytes).new(value)
    end

    def to_db(value : Bytes)
      value
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
