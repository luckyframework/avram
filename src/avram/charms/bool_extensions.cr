struct Bool
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Bool
    include Avram::Type(Bool)

    def parse(value : String)
      if %w(true 1).includes? value
        true
      elsif %w(false 0).includes? value
        false
      else
        failed_cast
      end
    end

    def parse(value : Bool)
      value
    end

    def parse(values : Array(Bool))
      values
    end

    def to_db(value : Bool)
      value.to_s
    end

    def to_db(values : Array(Bool))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
