require "./base"

module Avram::Migrator::Columns
  class AddInt64 < Base
    @default : Int64 | Int32 | Nil = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "bigint"
    end

    def formatted_default
      default.to_s
    end
  end
end
