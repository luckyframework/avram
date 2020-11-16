require "./base"

module Avram::Migrator::Columns::PrimaryKeys
  class UUIDPrimaryKey < Base
    def initialize(@name)
    end

    def column_type : String
      "uuid"
    end
  end
end
