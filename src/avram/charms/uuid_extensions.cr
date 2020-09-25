struct UUID
  def self.adapter
    Lucky
  end

  module LuckyConverter
    def self.from_rs(rs)
      rs.read(String?).try { |uuid| UUID.new(uuid) }
    end
  end

  module Lucky
    alias ColumnType = String
    include Avram::Type

    def parse(value : UUID)
      SuccessfulCast(UUID).new(value)
    end

    def parse(values : Array(UUID))
      SuccessfulCast(Array(UUID)).new values
    end

    def parse(value : String)
      SuccessfulCast(UUID).new(UUID.new(value))
    rescue
      FailedCast.new
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
