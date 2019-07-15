struct Bool
  def blank?
    false
  end

  module Lucky
    alias ColumnType = Bool
    include Avram::Type

    def parse(value : String)
      if %w(true 1).includes? value
        SuccessfulCast(Bool).new true
      elsif %w(false 0).includes? value
        SuccessfulCast(Bool).new false
      else
        FailedCast.new
      end
    end

    def parse(value : Bool)
      SuccessfulCast(Bool).new value
    end

    def parse(values : Array(Bool))
      SuccessfulCast(Array(Bool)).new values
    end

    def parse(values : Array(String))
      values = values.map {|value| parse(value).value }.as(Array(Bool))
      parse(values)
    end

    def to_db(value : Bool)
      value.to_s
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
