require "./base"

module Avram::Migrator::Columns
  class BoolColumn < Base
    @default : Array(Bool) | Bool | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "boolean"
    end
  end
end
