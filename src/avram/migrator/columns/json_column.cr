require "./base"

module Avram::Migrator::Columns::JSON
  class AnyColumn(T) < Base
    @default : ::JSON::Any? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type : String
      "jsonb"
    end

    def self.prepare_value_for_database(value)
      escape_literal value.to_json
    end
  end
end
