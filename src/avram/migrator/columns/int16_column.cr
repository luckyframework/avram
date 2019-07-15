require "./base"

module Avram::Migrator::Columns
  class Int16Column < Base
    @default : Int16 | Int32 | Nil = nil

    def initialize(@name, @nilable, @default, @array)
    end

    def column_type
      "smallint"
    end
  end
end
