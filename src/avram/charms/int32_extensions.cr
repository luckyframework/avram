struct Int32
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int32
    extend Avram::Type

    def self.from_db!(value : Int32)
      value
    end

    def self._parse_attribute(value : String)
     Avram::Type::SuccessfulCast(Int32).new value.to_i
    rescue ArgumentError
     Avram::Type::FailedCast.new
    end

    def self._parse_attribute(value : Int32)
     Avram::Type::SuccessfulCast(Int32).new(value)
    end

    def self._parse_attribute(value : Int64)
     Avram::Type::SuccessfulCast(Int32).new value.to_i32
    rescue OverflowError
     Avram::Type::FailedCast.new
    end

    def self._parse_attribute(values : Array(Int32))
     Avram::Type::SuccessfulCast(Array(Int32)).new values
    end

    def self.to_db(value : Int32)
      value.to_s
    end

    def self.to_db(values : Array(Int32))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)

      def select_sum : Int64?
        super.as(Int64?)
      end

      def select_sum! : Int64
        select_sum || 0_i64
      end
    end
  end
end
