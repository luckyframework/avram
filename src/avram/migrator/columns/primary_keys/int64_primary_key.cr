require "./base"

module Avram::Migrator::Columns::PrimaryKeys
  class Int64PrimaryKey < Base
    def initialize(@name)
    end

    def column_type : String
      "bigserial"
    end
  end
end
