require "./base"

module Avram::Migrator::Columns
  class BytesColumn(T) < Base
    @default : T | Bytes? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type : String
      "bytea"
    end
  end
end
