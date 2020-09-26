struct Bool
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = Bool
    extend Avram::Type

    def self._parse_attribute(value : String)
      if %w(true 1).includes? value
       Avram::Type::SuccessfulCast(Bool).new true
      elsif %w(false 0).includes? value
       Avram::Type::SuccessfulCast(Bool).new false
      else
       Avram::Type::FailedCast.new
      end
    end

    def self._parse_attribute(value : Bool)
     Avram::Type::SuccessfulCast(Bool).new value
    end

    def self._parse_attribute(values : Array(Bool))
     Avram::Type::SuccessfulCast(Array(Bool)).new values
    end

    def self.to_db(value : Bool)
      value.to_s
    end

    def self.to_db(values : Array(Bool))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
