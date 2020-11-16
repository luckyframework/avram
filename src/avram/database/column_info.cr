module Avram
  struct Database::ColumnInfo
    include DB::Serializable

    property table_catalog : String
    property table_schema : String
    property table_name : String
    property table_type : String
    property column_name : String
    property is_nullable : String

    def nilable?
      is_nullable == "YES"
    end

    def table
      TableInfo.new(
        table_name,
        table_type,
        table_schema
      )
    end
  end
end
