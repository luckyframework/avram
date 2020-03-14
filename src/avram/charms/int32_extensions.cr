struct Int32
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Int32
    include Avram::Type(Int32)

    def from_db!(value : Int32)
      value
    end

    def parse(value : String)
      value.to_i
    rescue ArgumentError
      failed_cast
    end

    def parse(value : Int32)
      value
    end

    def parse(value : Int64)
      value.to_i32
    rescue OverflowError
      failed_cast
    end

    def parse(values : Array(Int32))
      values
    end

    def to_db(value : Int32)
      value.to_s
    end

    def to_db(values : Array(Int32))
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
