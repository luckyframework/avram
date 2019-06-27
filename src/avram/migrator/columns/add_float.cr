require "./base"

module Avram::Migrator::Columns
  class AddFloat < Base
    private getter precision, scale

    @default : Float64 | Float32 | Nil = nil
    @precision : Int32?
    @scale : Int32?

    def initialize(@name, @nilable, @default, @precision, @scale)
    end

    def initialize(@name, @nilable, @default)
    end

    def column_type
      if precision && scale
        "decimal(#{precision},#{scale})"
      else
        "decimal"
      end
    end

    def formatted_default
      default.to_s
    end
  end

  class AddFloat32 < AddFloat
  end

  class AddFloat64 < AddFloat
  end
end
