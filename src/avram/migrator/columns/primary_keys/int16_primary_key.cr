require "./base"

module Avram::Migrator::Columns::PrimaryKeys
  class Int16PrimaryKey < Base
    def initialize(@name)
    end

    def column_type : String
      "smallserial"
    end
  end
end
