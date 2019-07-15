require "./base"

module Avram::Migrator::Columns
  class StringColumn < Base
    @default : (Array(String) | String | Nil) = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "text"
    end
  end
end
