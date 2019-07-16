require "./base"

module Avram::Migrator::Columns
  class TimeColumn < Base
    @default : Array(Time) | Time | Symbol | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
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
