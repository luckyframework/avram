require "./base"

module Avram::Migrator::Columns
  class AddBool < Base
    @default : Bool? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "boolean"
    end

    def formatted_default
      default.to_s
    end
  end
end
