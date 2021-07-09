abstract struct Enum
  def self.adapter
    Lucky(self)
  end

  module Lucky(T)
    include Avram::Type
    alias ColumnType = Int32

    def parse(value : String)
      if result = T.parse?(value)
        SuccessfulCast.new(result)
      else
        FailedCast.new
      end
    end

    def parse(value : Int32)
      if result = T.from_value?(value)
        SuccessfulCast.new(result)
      else
        FailedCast.new
      end
    end

    def parse(value : T)
      SuccessfulCast.new(value)
    end

    def to_db(value : T)
      value.value.to_s
    end

    def criteria(query : V, column) forall V
      Avram::Criteria(V, T).new(query, column)
    end
  end
end
