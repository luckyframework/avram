abstract class Avram::Database
  alias FiberId = UInt64

  @@db : DB::Database? = nil
  class_getter transactions = {} of FiberId => DB::Transaction

  macro inherited
    Habitat.create do
      setting url : String
    end
  end

  # TODO: Add a fallback 'configure' that raises at compile time and says
  # to create a Database class

  # Rollback the current transaction
  def self.rollback
    new.rollback
  end

  # runs a SQL `TRUNCATE` on all tables in the database
  def self.truncate
    new.truncate
  end

  def self.transaction
    new.transaction do |*yield_args|
      yield *yield_args
    end
  end

  def self.run
    new.run do |*yield_args|
      yield *yield_args
    end
  end

  def url
    settings.url
  end

  protected def run
    yield current_transaction.try(&.connection) || db
  end

  private def db
    @@db ||= Avram::Connection.new(settings.url, database_class: self.class).open
  end

  private def current_transaction : DB::Transaction?
    transactions[Fiber.current.object_id]?
  end

  protected def truncate
    DatabaseCleaner.new(self).truncate
  end

  protected def rollback
    raise Avram::Rollback.new
  end

  protected def transaction : Bool
    if current_transaction
      yield
    else
      wrap_in_transaction do
        yield
      end
    end
  end

  private def transactions
    self.class.transactions
  end

  private def wrap_in_transaction
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

  def table_names
    tables_with_schema(excluding: "migrations")
  end

  def tables_with_schema(excluding : String)
    select_rows <<-SQL
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema='public'
    AND table_type='BASE TABLE'
    AND table_name != '#{excluding}';
    SQL
  end

  def select_rows(statement)
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

  def table_columns(table_name)
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
    private getter database

    def initialize(@database : Avram::Database)
    end

    def truncate
      table_names = database.table_names
      return if table_names.empty?
      statement = ("TRUNCATE TABLE #{table_names.map { |name| name }.join(", ")} RESTART IDENTITY CASCADE;")
      database.run do |db|
        db.exec statement
      end
    end
  end
end
