struct Float64
  extend Avram::Type

  def self._from_db!(value : Float64)
    value
  end

  def self._from_db!(value : PG::Numeric)
    value.to_f
  end

  def self._parse_attribute(value : PG::Numeric)
    Avram::Type::SuccessfulCast(Float64).new(value.to_f)
  end

  def self._parse_attribute(values : Array(PG::Numeric))
    Avram::Type::SuccessfulCast(Array(Float64)).new values.map(&.to_f)
  end

  def self._parse_attribute(value : String)
    Avram::Type::SuccessfulCast(Float64).new value.to_f64
  rescue ArgumentError
    Avram::Type::FailedCast.new
  end

  def self._parse_attribute(value : Int32)
    Avram::Type::SuccessfulCast(Float64).new value.to_f64
  end

  def self._parse_attribute(value : Int64)
    Avram::Type::SuccessfulCast(Float64).new value.to_f64
  end

  def self._to_db(values : Array(Float64))
    PQ::Param.encode_array(values)
  end

  module Lucky
    alias ColumnType = Float64

    class Criteria(T, V) < Avram::Criteria(T, V)
      include Avram::BetweenCriteria(T, V)

      def select_sum : Float64?
        if sum = super
          sum.as(PG::Numeric).to_f
        end
      end

      def select_sum! : Float64
        select_sum || 0_f64
      end
    end
  end
end
