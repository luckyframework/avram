require "./base"

module Avram::Migrator::Columns
  class AddJSON::Any < Base
    @default : JSON::Any? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "jsonb"
    end

    def default
      super.to_json
    end
  end
end
