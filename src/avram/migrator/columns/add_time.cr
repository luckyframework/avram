require "./base"

module Avram::Migrator::Columns
  class AddTime < Base
    @default : Time | Symbol | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "timestamptz"
    end

    def formatted_default
      value = default
      if value == :now
        "NOW()"
      elsif value.is_a?(Time)
        "'#{value.to_utc}'"
      else
        raise "Unrecognized default :#{value} for a timestamptz. Please use a Time object or :now for current timestamp."
      end
    end
  end
end
