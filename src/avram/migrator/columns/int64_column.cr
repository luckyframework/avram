require "./base"

module Avram::Migrator::Columns
  class Int64Column(T) < Base
    @default : T | Int32 | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type : String
      "bigint"
    end
  end
end
