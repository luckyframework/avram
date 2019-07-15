require "./base"

module Avram::Migrator::Columns
  class Int32Column < Base
    @default : Int32? = nil

    def initialize(@name, @nilable, @default, @array)
    end

    def column_type
      "int"
    end
  end
end
