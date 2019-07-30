require "./base"

module Avram::Migrator::Columns
  class Int16Column(T) < Base
    @default : T | Int32 | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type : String
      "smallint"
    end
  end
end
