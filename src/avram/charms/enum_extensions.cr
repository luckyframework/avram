require "./int32_extensions"

abstract struct Enum
  def self.adapter
    Lucky(self)
  end

  module Lucky(T)
    include Avram::Type
    alias ColumnType = Int32 | Int64

    def parse(value : String)
      is_int = value.to_i?
      return parse(is_int) if is_int

      if result = T.parse?(value)
        SuccessfulCast.new(result)
      else
        FailedCast.new
      end
    end

    def parse(value : Int)
      if result = T.from_value?(value)
        SuccessfulCast.new(result)
      else
        FailedCast.new
      end
    end

    def parse(value : Array(T))
      SuccessfulCast(Array(T)).new value
    end

    def parse(values : Array(Int))
      results = values.map { |i| parse(i) }
      if results.all?(SuccessfulCast)
        parse(results.map(&.value.as(T)))
      else
        FailedCast.new
      end
    end

    def parse(value : T)
      SuccessfulCast.new(value)
    end

    def to_db(values : Array(T))
      encoded = values.map { |value| to_db(value) }.as(Array(String))
      PQ::Param.encode_array(encoded)
    end

    def to_db(value : T) : String
      value.value.to_s
    end

    def criteria(query : V, column) forall V
      Criteria(V, T).new(query, column)
    end

    class Criteria(T, V) < Int32::Lucky::Criteria(T, V)
      def select_min : V?
        rows.exec_scalar(&.select_min(column))
          .as(Int32?)
          .try { |min| V.adapter.parse!(min) }
      end

      def select_max : V?
        rows.exec_scalar(&.select_max(column))
          .as(Int32?)
          .try { |max| V.adapter.parse!(max) }
      end
    end
  end
end
