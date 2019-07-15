require "./base"

module Avram::Migrator::Columns
  class FloatColumn < Base
    private getter precision, scale

    @default : Float64 | Float32 | Nil = nil
    @precision : Int32?
    @scale : Int32?

    def initialize(@name, @nilable, @default, @precision, @scale)
    end

    def initialize(@name, @nilable, @default, @array)
    end

    def column_type
      if precision && scale
        "decimal(#{precision},#{scale})"
      else
        "decimal"
      end
    end
  end

  class Float32Column < FloatColumn
  end

  class Float64Column < FloatColumn
  end
end
