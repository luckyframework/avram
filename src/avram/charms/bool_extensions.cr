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
      true_vals = %w(true 1)
      false_vals = %w(false 0)
      if true_vals.includes? value
        SuccessfulCast(Bool).new true
      elsif false_vals.includes? value
        SuccessfulCast(Bool).new false
      else
        FailedCast.new("Value ->#{value}<- could not be converted to boolean - allowed values: #{true_vals + false_vals}")
      end
    end

    def parse(value : Bool)
      SuccessfulCast(Bool).new value
    end

    def parse(values : Array(Bool))
      SuccessfulCast(Array(Bool)).new values
    end

    def to_db(value : Bool)
      value.to_s
    end

    def to_db(values : Array(Bool))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
