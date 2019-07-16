require "./base"

module Avram::Migrator::Columns
  class Int16Column < Base
    @default : Array(Int16) | Int16 | Int32 | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "smallint"
    end
  end
end
