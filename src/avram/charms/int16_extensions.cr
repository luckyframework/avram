struct Int16
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int16
    extend Avram::Type

    def self.from_db!(value : Int16)
      value
    end

    def self.parse(value : Int16)
     Avram::Type::SuccessfulCast(Int16).new(value)
    end

    def self.parse(values : Array(Int16))
     Avram::Type::SuccessfulCast(Array(Int16)).new values
    end

    def self.parse(value : String)
     Avram::Type::SuccessfulCast(Int16).new value.to_i16
    rescue ArgumentError
     Avram::Type::FailedCast.new
    end

    def self.parse(value : Int32)
     Avram::Type::SuccessfulCast(Int16).new value.to_i16
    rescue OverflowError
     Avram::Type::FailedCast.new
    end

    def self.to_db(value : Int16)
      value.to_s
    end

    def self.to_db(values : Array(Int16))
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
