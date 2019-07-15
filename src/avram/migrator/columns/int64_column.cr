require "./base"

module Avram::Migrator::Columns
  class Int64Column < Base
    @default : Int64 | Int32 | Nil = nil

    def initialize(@name, @nilable, @default, @array)
    end

    def column_type
      "bigint"
    end
  end
end
