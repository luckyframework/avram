struct UUID
  def blank?
    false
  end

  module Lucky
    alias ColumnType = String
    include LuckyRecord::Type

    def parse(value : UUID)
      SuccessfulCast(UUID).new(value)
    end

    def parse(value : String)
      SuccessfulCast(UUID).new(UUID.new(value))
    rescue
      FailedCast.new
    end

    def to_db(value : UUID)
      value.to_s
    end

    class Criteria(T, V) < LuckyRecord::Criteria(T, V)
    end
  end
end
