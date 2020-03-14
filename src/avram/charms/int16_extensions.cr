struct Int16
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int16
    include Avram::Type(Int16)

    def from_db!(value : Int16)
      value
    end

    def parse(value : Int16)
      value
    end

    def parse(values : Array(Int16))
      values
    end

    def parse(value : String)
      value.to_i16
    rescue ArgumentError
      failed_cast
    end

    def parse(value : Int32)
      value.to_i16
    rescue OverflowError
      failed_cast
    end

    def to_db(value : Int16)
      value.to_s
    end

    def to_db(values : Array(Int16))
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
