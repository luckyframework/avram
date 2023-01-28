require "./base"

module Avram::Migrator::Columns::PrimaryKeys
  class StringPrimaryKey < Base
    def initialize(@name)
    end

    def column_type : String
      "string"
    end

    def build : String
      %(  #{name} #{column_type} PRIMARY KEY)
    end
  end
end
