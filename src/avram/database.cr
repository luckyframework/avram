abstract class Avram::Database
  alias FiberId = UInt64

  @@db : DB::Database? = nil
  @@lock = Mutex.new
  class_getter transactions = {} of FiberId => DB::Transaction

  macro inherited
    Habitat.create do
      setting credentials : Avram::Credentials, example: %(Avram::Credentials.new(database: "my_database", username: "postgres") or Avram::Credentials.parse(ENV["DB_URL"]))
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

  @@database_info : DatabaseInfo?

  def self.database_info : DatabaseInfo
    @@database_info ||= DatabaseInfo.load(self)
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

  # Methods without a block
  {% for crystal_db_alias in [:exec, :scalar, :query, :query_all, :query_one, :query_each] %}
    # Same as crystal-db's `DB::QueryMethods#{{ crystal_db_alias.id }}` but with instrumentation
    def {{ crystal_db_alias.id }}(query, *args_, args : Array? = nil, queryable : String? = nil, **named_args)
      publish_query_event(query, args_, args, queryable) do
        run do |db|
          db.{{ crystal_db_alias.id }}(query, *args_, args: args)
        end
      end
    end

    # Same as crystal-db's `DB::QueryMethods#{{ crystal_db_alias.id }}` but with instrumentation
    def self.{{ crystal_db_alias.id }}(query, *args_, args : Array? = nil, queryable : String? = nil, **named_args)
      new.{{ crystal_db_alias.id }}(query, *args_, args: args, queryable: queryable)
    end
  {% end %}

  # Methods with a block
  {% for crystal_db_alias in [:query, :query_all, :query_one, :query_each] %}
    # Same as crystal-db's `DB::QueryMethods#{{ crystal_db_alias }}` but with instrumentation
    def {{ crystal_db_alias.id }}(query, *args_, args : Array? = nil, queryable : String? = nil, **named_args)
      publish_query_event(query, args_, args, queryable) do
        run do |db|
          db.{{ crystal_db_alias.id }}(query, *args_, args: args) do |*yield_args|
            yield *yield_args
          end
        end
      end
    end

    # Same as crystal-db's `DB::QueryMethods#{{ crystal_db_alias }}` but with instrumentation
    def self.{{ crystal_db_alias.id }}(query, *args_, args : Array? = nil, queryable : String? = nil, **named_args)
      new.{{ crystal_db_alias.id }}(query, *args_, args: args, queryable: queryable) do |*yield_args|
        yield *yield_args
      end
    end
  {% end %}

  def publish_query_event(query, args_, args, queryable)
    logging_args = DB::EnumerableConcat.build(args_, args).to_s
    Avram::Events::QueryEvent.publish(query: query, args: logging_args, queryable: queryable) do
      yield
    end
  rescue e : PQ::PQError
    Avram::Events::FailedQueryEvent.publish(
      error_message: e.message.to_s,
      query: query,
      queryable: queryable,
      args: logging_args
    )
    raise e
  end

  def self.credentials
    settings.credentials
  end

  protected def url
    settings.credentials.url
  end

  def self.run
    new.run do |*yield_args|
      yield *yield_args
    end
  end

  # :nodoc:
  def run
    yield current_transaction.try(&.connection) || db
  end

  private def db : DB::Database
    @@db ||= @@lock.synchronize do
      # check @@db again because a previous request could have set it after
      # the first time it was checked
      @@db || Avram::Connection.new(url, database_class: self.class).open
    end
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

  class DatabaseCleaner
    private getter database : Avram::Database
    private getter table_names : Array(String)

    def initialize(@database)
      @table_names = database.class
        .database_info
        .table_infos
        .select(&.table?)
        .reject(&.migrations_table?)
        .map(&.table_name)
    end

    def truncate
      return if table_names.empty?

      statement = ("TRUNCATE TABLE #{table_names.map { |name| name }.join(", ")} RESTART IDENTITY CASCADE;")
      database.exec statement
    end

    def delete
      return if table_names.empty?

      table_names.each do |t|
        statement = ("DELETE FROM #{t}")
        database.exec statement
      end
    end
  end
end
