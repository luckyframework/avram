require "./base"

module Avram::Migrator::Columns
  class AddJSON::Any < Base
    @default : JSON::Any? = nil

    def initialize(@name, @nilable, @default)
    end

    def column_type
      "jsonb"
    end

    def formatted_default
      "'#{default.to_json.gsub(/'/, "''")}'"
    end
  end
end
