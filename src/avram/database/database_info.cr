module Avram
  struct Database::DatabaseInfo
    def self.load(database)
      sql = <<-SQL
     SELECT columns.table_name,
            tables.table_type,
            columns.table_schema,
            columns.table_catalog,
            columns.column_name,
            columns.is_nullable
     FROM information_schema.columns as columns
     JOIN information_schema.tables as tables
       ON tables.table_name = columns.table_name
       AND tables.table_catalog = columns.table_catalog
       AND tables.table_schema = columns.table_schema
     WHERE columns.table_schema='public';
     SQL
      column_infos = database.query(sql) { |rs| ColumnInfo.from_rs(rs) }

      grouped = column_infos.group_by(&.table)
      grouped.each do |table, columns|
        columns.each { |c| table.columns << c }
      end
      table_infos = grouped.keys
      new(table_infos)
    end

    property table_infos : Array(TableInfo)

    def initialize(@table_infos)
    end

    def table?(name : String)
      table_names.includes?(name)
    end

    def table_names
      table_infos.map(&.table_name)
    end

    def table(name : String) : TableInfo?
      table_infos.find { |table_info| table_info.table_name == name }
    end
  end
end
