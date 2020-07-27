abstract class Avram::Database
  alias FiberId = UInt64

  @@db : DB::Database? = nil
  class_getter transactions = {} of FiberId => DB::Transaction

  macro inherited
    Habitat.create do
      setting credentials : Avram::Credentials, example: %(Avram::Credentials.build(database: "my_database", username: "postgres") or Avram::Credentials.parse(ENV["DB_URL"]))
    end
  end

  # :nodoc:
  def self.configure(*args, **named_args, &block)
    {% raise <<-ERROR
      You can't configure Avram::Database directly.

      Try this...

        ▸ Configure your class that inherits from Avram::Database. Typically 'AppDatabase'.
        ▸ If you have not created a class that inherits from Avram::Database, create one and configure it.
      ERROR
    %}
  end

  # Rollback the current transaction
  def self.rollback
    new.rollback
  end

  # Run a SQL `TRUNCATE` on all tables in the database
  def self.truncate
    new.truncate
  end

  # Run a SQL `DELETE` on all tables in the database
  def self.delete
    new.delete
  end

  # Wrap the block in a database transaction
  #
  # ```
  # AppDatabase.transaction do
  #   # Create, read, update
  #   # Force a rollback with AppDatabase.rollback
  # end
  # ```
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

  def self.credentials
    settings.credentials
  end

  protected def url
    settings.credentials.url
  end

  # :nodoc:
  def run
    yield current_transaction.try(&.connection) || db
  end

  private def db
    @@db ||= Avram::Connection.new(url, database_class: self.class).open
  end

  private def current_transaction : DB::Transaction?
    transactions[Fiber.current.object_id]?
  end

  protected def truncate
    DatabaseCleaner.new(self).truncate
  end

  protected def delete
    DatabaseCleaner.new(self).delete
  end

  protected def rollback
    raise Avram::Rollback.new
  end

  # :nodoc:
  def transaction : Bool
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

    def delete
      table_names = database.table_names
      return if table_names.empty?
      table_names.each do |t|
        statement = ("DELETE FROM #{t}")
        database.run do |db|
          db.exec statement
        end
      end
    end
  end
end
