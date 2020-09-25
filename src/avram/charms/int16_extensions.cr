struct Int16
  extend Avram::Type

  def self.parse_attribute(value : String)
    Avram::Type::SuccessfulCast(Int16).new value.to_i16
  rescue ArgumentError
    Avram::Type::FailedCast.new
  end

  def self.parse_attribute(value : Int32)
    Avram::Type::SuccessfulCast(Int16).new value.to_i16
  rescue OverflowError
    Avram::Type::FailedCast.new
  end

  module Lucky
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
