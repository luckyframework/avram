require "./base"

module Avram::Migrator::Columns
  class AddInt32 < Base
    @default : Int32? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "int"
    end

    def formatted_default
      default.to_s
    end
  end
end
