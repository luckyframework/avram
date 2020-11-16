module Avram
  class OrderBy
    enum NullSorting
      DEFAULT
      NULLS_FIRST
      NULLS_LAST

      def to_s
        super.gsub("_", " ")
      end
    end

    enum Direction
      ASC
      DESC
    end

    def_clone

    getter column
    getter direction
    getter nulls

    def initialize(@column : String | Symbol, @direction : Direction, @nulls : NullSorting = :default)
    end

    def reversed
      @direction = @direction.asc? ? Direction::DESC : Direction::ASC
      self
    end

    def prepare
      String.build do |str|
        str << "#{column} #{direction}"
        str << " #{nulls}" unless nulls.default?
      end
    end
  end
end
