require "./base"

module Avram::Migrator::Columns
  class Int32Column(T) < Base
    @default : T? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type : String
      "int4"
    end
  end
end
