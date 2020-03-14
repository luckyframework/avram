struct UUID
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = String
    include Avram::Type(UUID)

    def parse(value : UUID)
      value
    end

    def parse(values : Array(UUID))
      values
    end

    def parse(value : String)
      UUID.new(value)
    rescue
      failed_cast
    end

    def to_db(value : UUID)
      value.to_s
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
    end
  end
end
