require "./base"

module Avram::Migrator::Columns
  class BoolColumn(T) < Base
    @default : T | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "boolean"
    end
  end
end
