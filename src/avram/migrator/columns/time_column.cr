require "./base"

module Avram::Migrator::Columns
  class TimeColumn(T) < Base
    @default : T | Symbol | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type : String
      "timestamptz"
    end

    def self.prepare_value_for_database(value)
      if value == :now
        "NOW()"
      elsif value.is_a?(Time)
        escape_literal value.to_utc.to_s
      else
        raise "Unrecognized value :#{value} for a timestamptz. Please use a Time object or :now for current timestamp."
      end
    end
  end
end
