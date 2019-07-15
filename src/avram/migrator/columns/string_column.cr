require "./base"

module Avram::Migrator::Columns
  class StringColumn < Base
    @default : String? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "text"
    end
  end
end
