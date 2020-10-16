struct UUID
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = UUID
    include Avram::Type

    def parse(value : UUID)
      SuccessfulCast(UUID).new(value)
    end

    def parse(values : Array(UUID))
      SuccessfulCast(Array(UUID)).new values
    end

    def parse(value : String)
      return parse(nil) if value.blank?
      SuccessfulCast(UUID).new(UUID.new(value))
    rescue
      FailedCast.new
    end

    def to_db(value : UUID)
      value.to_s
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
