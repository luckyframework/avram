class String
  def self.adapter
    Lucky
  end

  module Lucky
    alias ColumnType = String
    include Avram::Type

    def from_rs(rs : PG::ResultSet)
      rs.read(String?)
    end

    def parse(value : String)
      SuccessfulCast(String).new(value)
    end

    def parse(values : Array(String))
      SuccessfulCast(Array(String)).new(values)
    end

    def to_db(value : String)
      value
    end

    def to_db(values : Array(String))
      PQ::Param.encode_array(values)
    end

    class Criteria(T, V) < Avram::Criteria(T, V)
      @upper = false
      @lower = false

      def like(value : String) : T
        add_clause(Avram::Where::Like.new(column, value))
      end

      def ilike(value : String) : T
        add_clause(Avram::Where::Ilike.new(column, value))
      end

      def upper
        @upper = true
        self
      end

      def lower
        @lower = true
        self
      end

      def column
        if @upper
          "UPPER(#{@column})"
        elsif @lower
          "LOWER(#{@column})"
        else
          @column
        end
      end
    end
  end
end
