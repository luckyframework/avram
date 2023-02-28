abstract class Avram::Database
  alias FiberId = UInt64

  @@db : DB::Database? = nil
  @@lock = Mutex.new
  class_getter connections = {} of FiberId => DB::Connection
  class_property lock_id : UInt64?

  macro inherited
    Habitat.create do
      setting credentials : Avram::Credentials, example: %(Avram::Credentials.new(database: "my_database", username: "postgres") or Avram::Credentials.parse(ENV["DB_URL"]))
    end
  end

  # :nodoc:
  def self.configure(*args, **named_args, &_block)
    {% raise <<-ERROR
      You can't configure Avram::Database directly.

      Try this...

        ▸ Configure your class that inherits from Avram::Database. Typically 'AppDatabase'.
        ▸ If you have not created a class that inherits from Avram::Database, create one and configure it.
      ERROR
    %}
  end

  def self.setup_connection(&block : DB::Connection -> Nil)
    new.db.setup_connection do |conn|
      block.call conn
    end
  end

  def self.verify_connection
    new.connection.open.close
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

  # Listens for `pg_notify()` calls on each channel in `channels`
  # Yields a `PQ::Notification` object with `channel`, `payload`, and `pid`.
  #
  # ```
  # # pg_notify("callback", "123")
  # AppDatabase.listen("callback", "jobs") do |notification|
  #   notification.channel # => "callback"
  #   notification.payload # => "123"
  # end
  # ```
  def self.listen(*channels : String, &block : PQ::Notification ->) : Nil
    new.listen(*channels, &block)
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
  def self.transaction(&)
    new.transaction do |*yield_args|
      yield *yield_args
    end
  end

  # Methods without a block
  {% for crystal_db_alias in [:exec, :scalar, :query, :query_all, :query_one, :query_one?] %}
    # Same as crystal-db's `DB::QueryMethods#{{ crystal_db_alias.id }}` but with instrumentation
    def {{ crystal_db_alias.id }}(query, *args_, args : Array? = nil, queryable : String? = nil, **named_args)
      publish_query_event(query, args_, args, queryable) do
        run do |db|
          db.{{ crystal_db_alias.id }}(query, *args_, **named_args, args: args)
        end
      end
    end

    # Same as crystal-db's `DB::QueryMethods#{{ crystal_db_alias.id }}` but with instrumentation
    def self.{{ crystal_db_alias.id }}(query, *args_, args : Array? = nil, queryable : String? = nil, **named_args)
      new.{{ crystal_db_alias.id }}(query, *args_, **named_args, args: args, queryable: queryable)
    end
  {% end %}

  # Methods with a block
  {% for crystal_db_alias in [:query, :query_all, :query_one, :query_one?, :query_each] %}
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

  def publish_query_event(query, args_, args, queryable, &)
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

  def self.run(&)
    new.run do |*yield_args|
      yield *yield_args
    end
  end

  # :nodoc:
  def run(&)
    with_connection do |conn|
      yield conn
    end
  end

  # :nodoc:
  def listen(*channels : String, &block : PQ::Notification ->) : Nil
    connection.connect_listen(*channels, &block)
  end

  protected def connection : Avram::Connection
    Avram::Connection.new(url, database_class: self.class)
  end

  protected def db : DB::Database
    @@db ||= @@lock.synchronize do
      # check @@db again because a previous request could have set it after
      # the first time it was checked
      @@db || connection.open
    end
  end

  # singular place to retrieve a DB::Connection
  # must be passed a block and we
  # try to release the connection back to the pool
  # once the block is finished
  private def with_connection(&)
    key = object_id
    connections[key] ||= db.checkout
    connection = connections[key]

    begin
      yield connection
    ensure
      if !connection._avram_in_transaction?
        connection.release
        connections.delete(key)
      end
    end
  end

  private def object_id : UInt64
    self.class.lock_id || Fiber.current.object_id
  end

  private def current_transaction(connection : DB::Connection) : DB::Transaction?
    connection._avram_stack.last?
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
  def transaction(&) : Bool
    with_connection do |conn|
      if current_transaction(conn).try(&._avram_joinable?)
        yield
        true
      else
        wrap_in_transaction(conn) do
          yield
        end
      end
    end
  end

  private def connections
    self.class.connections
  end

  private def wrap_in_transaction(conn, &)
    (current_transaction(conn) || conn).transaction do
      yield
    end
    true
  rescue e : Avram::Rollback
    false
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
