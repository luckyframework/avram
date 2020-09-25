class String
  extend Avram::Type

  def self.parse_attribute(value : String)
    Avram::Type::SuccessfulCast(String).new(value)
  end

  def self.parse_attribute(values : Array(String))
    Avram::Type::SuccessfulCast(Array(String)).new(values)
  end

  def self.adapter
    self
  end

  module Lucky
    alias ColumnType = String

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
