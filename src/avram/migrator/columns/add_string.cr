require "./base"

module Avram::Migrator::Columns
  class AddString < Base
    @default : String? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "text"
    end

    def formatted_default
      # String.dump maybe
      "'#{default}'"
    end
  end
end
