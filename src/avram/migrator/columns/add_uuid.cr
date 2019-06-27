require "./base"

module Avram::Migrator::Columns
  class AddUUID < Base
    @default : UUID? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "uuid"
    end

    def formatted_default
      "'#{default}'"
    end
  end
end
