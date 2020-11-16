require "./base"

module Avram::Migrator::Columns
  abstract class FloatColumn(T) < Base
    private getter precision, scale

    @default : T | Float32 | Nil = nil
    @precision : Int32?
    @scale : Int32?

    def initialize(@name, @nilable, @default, @precision, @scale)
    end

    def initialize(@name, @nilable, @default)
    end

    def column_type : String
      if precision && scale
        "decimal(#{precision},#{scale})"
      else
        "decimal"
      end
    end
  end

  class Float32Column(T) < FloatColumn(T)
  end

  class Float64Column(T) < FloatColumn(T)
  end
end
