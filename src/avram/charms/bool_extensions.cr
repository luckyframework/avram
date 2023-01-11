struct Bool
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Bool
    include Avram::Type

    def self.criteria(query : T, column) forall T
      Criteria(T, Bool).new(query, column)
    end

    def parse(value : String)
      if %w(true 1).includes? value
        SuccessfulCast(Bool).new true
      elsif %w(false 0).includes? value
        SuccessfulCast(Bool).new false
      else
        FailedCast.new
      end
    end

    def parse(value : Bool)
      SuccessfulCast(Bool).new value
    end

    def parse(values : Array(Bool))
      SuccessfulCast(Array(Bool)).new values
    end

    def to_db(value : Bool) : String
      value.to_s
    end

    def to_db(values : Array(Bool))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
