struct Slice(T)
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Bytes
    include Avram::Type

    def self.criteria(query : T, column : Symbol | String) forall T
      Criteria(T, Bytes).new(query, column)
    end

    def from_db!(value : Bytes) : Bytes
      value
    end

    def parse(value : String)
      parse(value.to_slice)
    end

    def parse(value : Bytes) : SuccessfulCast(Bytes)
      SuccessfulCast(Bytes).new(value)
    end

    def to_db(value : Bytes)
      ssize = value.size * 2 + 2
      String.new(ssize) do |buffer|
        buffer[0] = '\\'.ord.to_u8
        buffer[1] = 'x'.ord.to_u8
        value.hexstring(buffer + 2)
        {ssize, ssize}
      end
    end

    def to_db(value : String) : String
      value
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
