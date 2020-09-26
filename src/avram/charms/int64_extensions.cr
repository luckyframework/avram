struct Int64
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int64
    extend Avram::Type

    def self._from_db!(value : Int64)
      value
    end

    def self._parse_attribute(value : Int64)
     Avram::Type::SuccessfulCast(Int64).new(value)
    end

    def self._parse_attribute(values : Array(Int64))
     Avram::Type::SuccessfulCast(Array(Int64)).new values
    end

    def self._parse_attribute(value : String)
     Avram::Type::SuccessfulCast(Int64).new value.to_i64
    rescue ArgumentError
     Avram::Type::FailedCast.new
    end

    def self._parse_attribute(value : Int32)
     Avram::Type::SuccessfulCast(Int64).new value.to_i64
    end

    def self._to_db(value : Int64)
      value.to_s
    end

    def self._to_db(values : Array(Int64))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)

      def select_sum : Int64?
        if sum = super
          sum.as(PG::Numeric).to_f.to_i64
        end
      end

      def select_sum! : Int64
        select_sum || 0_i64
      end
    end
  end
end
