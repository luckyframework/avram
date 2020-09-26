struct UUID
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = String
    extend Avram::Type

    def self.parse(value : UUID)
     Avram::Type::SuccessfulCast(UUID).new(value)
    end

    def self.parse(values : Array(UUID))
     Avram::Type::SuccessfulCast(Array(UUID)).new values
    end

    def self.parse(value : String)
     Avram::Type::SuccessfulCast(UUID).new(UUID.new(value))
    rescue
     Avram::Type::FailedCast.new
    end

    def self.to_db(value : UUID)
      value.to_s
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
