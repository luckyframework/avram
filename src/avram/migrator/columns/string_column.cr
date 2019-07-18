require "./base"

module Avram::Migrator::Columns
  class StringColumn(T) < Base
    @default : T | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "text"
    end
  end
end
