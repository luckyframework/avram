class LuckyRecord::Repo
  @@db : DB::Database? = nil

  Habitat.create do
    setting url : String
    setting lazy_load_enabled : Bool = true
  end

  def self.run
    yield db
  end

  def self.db
    @@db ||= DB.open(settings.url)
  end

  def self.truncate
    DatabaseCleaner.new.truncate
  end

  def self.table_names
    tables_with_schema(excluding: "schema_migrations")
  end

  def self.tables_with_schema(excluding : String)
    select_rows <<-SQL
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema='public'
    AND table_type='BASE TABLE'
    AND table_name != '#{excluding}';
    SQL
  end

  def self.select_rows(statement)
    rows = [] of String

    run do |db|
      db.query statement do |rs|
        rs.each do
          rows << rs.read(String)
        end
      end
    end

    rows
  end

  def self.table_columns(table_name)
    statement = <<-SQL
    SELECT column_name as name, is_nullable::boolean as nilable
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = '#{table_name}'
    SQL

    run { |db| db.query_all statement, as: TableColumn }
  end

  class TableColumn
    DB.mapping({
      name:    String,
      nilable: Bool,
    })
  end

  class DatabaseCleaner
    def truncate
      table_names = LuckyRecord::Repo.table_names
      return if table_names.empty?
      statement = ("TRUNCATE TABLE #{table_names.map { |name| name }.join(", ")} RESTART IDENTITY CASCADE;")
      LuckyRecord::Repo.run do |db|
        db.exec statement
      end
    end
  end
end
