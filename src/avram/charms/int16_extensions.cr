struct Int16
  extend Avram::Type

  def self.parse_attribute(value : Int16)
    Avram::Type::SuccessfulCast(Int16).new(value)
  end

  def self.parse_attribute(values : Array(Int16))
    Avram::Type::SuccessfulCast(Array(Int16)).new values
  end

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

  def self.adapter
    self
  end

  module Lucky
    alias ColumnType = Int16

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
