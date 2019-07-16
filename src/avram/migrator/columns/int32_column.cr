require "./base"

module Avram::Migrator::Columns
  class Int32Column < Base
    @default : Array(Int32) | Int32 | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "int"
    end
  end
end
