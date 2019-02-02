struct Bool
  def blank?
    false
  end

  module Lucky
    alias ColumnType = Bool
    include Avram::Type

    def self.parse(value : String)
      if %w(true 1).includes? value
        SuccessfulCast(Bool).new true
      elsif %w(false 0).includes? value
        SuccessfulCast(Bool).new false
      else
        FailedCast.new
      end
    end

    def self.parse(value : Bool)
      SuccessfulCast(Bool).new value
    end

    def self.to_db(value : Bool)
      value.to_s
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
