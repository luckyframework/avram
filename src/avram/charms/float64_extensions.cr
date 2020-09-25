struct Float64
  extend Avram::Type

  def self.parse_attribute(value : PG::Numeric)
    Avram::Type::SuccessfulCast(Float64).new(value.to_f)
  end

  def self.parse_attribute(values : Array(PG::Numeric))
    Avram::Type::SuccessfulCast(Array(Float64)).new values.map(&.to_f)
  end

  def self.parse_attribute(value : String)
    Avram::Type::SuccessfulCast(Float64).new value.to_f64
  rescue ArgumentError
    Avram::Type::FailedCast.new
  end

  def self.parse_attribute(value : Int32)
    Avram::Type::SuccessfulCast(Float64).new value.to_f64
  end

  def self.parse_attribute(value : Int64)
    Avram::Type::SuccessfulCast(Float64).new value.to_f64
  end

  def self.from_rs(rs)
    rs.read(PG::Numeric?).try &.to_f
  end

  module Lucky
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
