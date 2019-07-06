class Avram::Database
  alias FiberId = UInt64

  @@db : DB::Database? = nil
  private class_getter transactions = {} of FiberId => DB::Transaction

  Habitat.create do
    setting url : String
    setting lazy_load_enabled : Bool = true
    setting logger : Dexter::Logger = Dexter::Logger.new(nil)
  end

  def self.run
    yield current_transaction.try(&.connection) || db
  end

  def self.db
    @@db ||= Connection.open(settings.url)
  end

  def self.current_transaction : DB::Transaction?
    transactions[Fiber.current.object_id]?
  end

  # runs a SQL `TRUNCATE` on all tables in the database
  def self.truncate
    DatabaseCleaner.new.truncate
  end

  # Rollback the current transaction
  def self.rollback
    raise Avram::Rollback.new
  end

  def self.transaction : Bool
    if current_transaction
      yield
    else
      wrap_in_transaction do
        yield
      end
    end
  end

  def self.wrap_in_transaction
    db.transaction do |tx|
      transactions[Fiber.current.object_id] ||= tx
      yield
    end
    true
  rescue e : Avram::Rollback
    false
  ensure
    transactions.delete(Fiber.current.object_id)
  end

  def self.table_names
    tables_with_schema(excluding: "migrations")
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
      table_names = Avram::Database.table_names
      return if table_names.empty?
      statement = ("TRUNCATE TABLE #{table_names.map { |name| name }.join(", ")} RESTART IDENTITY CASCADE;")
      Avram::Database.run do |db|
        db.exec statement
      end
    end
  end
end
