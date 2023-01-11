struct UUID
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = UUID
    include Avram::Type

    def self.criteria(query : T, column) forall T
      Criteria(T, UUID).new(query, column)
    end

    def parse(value : UUID)
      SuccessfulCast(UUID).new(value)
    end

    def parse(values : Array(UUID))
      SuccessfulCast(Array(UUID)).new values
    end

    def parse(value : String)
      SuccessfulCast(UUID).new(UUID.new(value))
    rescue
      FailedCast.new
    end

    def to_db(value : UUID) : String
      value.to_s
    end

    def to_db(values : Array(UUID))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::IncludesCriteria(T, V)
    end
  end
end
