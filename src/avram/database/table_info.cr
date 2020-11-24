module Avram
  struct Database::TableInfo
    getter table_name : String
    getter table_type : String
    getter table_schema : String
    getter columns = [] of ColumnInfo

    def initialize(
      @table_name,
      @table_type,
      @table_schema
    )
    end

    def table?
      table_type == "BASE TABLE"
    end

    def view?
      table_type == "VIEW"
    end

    def column?(name : String)
      column_names.includes?(name)
    end

    def column_names
      columns.map(&.column_name)
    end

    def column(name : String) : ColumnInfo?
      columns.find(&.column_name.==(name))
    end

    def migrations_table?
      table_name == "migrations"
    end
  end
end
