require "./base"

module Avram::Migrator::Columns
  class StringColumn(T) < Base
    @default : T | Nil = nil
    private getter? case_sensitive : Bool

    def initialize(@name, @nilable, @default, @case_sensitive = true)
    end

    # If `case_sensitive?` is false then the column type is set to `citext`
    # which requires the `citext` extension to be enabled
    # otherwise the type is `text`
    def column_type : String
      case_sensitive? ? "text" : "citext"
    end
  end
end
