require "db"
require "pg"
require "colorize"

class Avram::Migrator::Runner
  MIGRATIONS_TABLE_NAME = "migrations"

  extend LuckyCli::TextHelpers

  @@migrations = [] of Avram::Migrator::Migration::V1.class

  def initialize(@quiet : Bool = false)
  end

  def self.db_name
    (URI.parse(database_url).path || "")[1..-1]
  end

  def self.db_host
    URI.parse(database_url).host || "localhost"
  end

  def self.db_port
    URI.parse(database_url).port || "5432"
  end

  def self.db_user
    URI.parse(database_url).user
  end

  def self.db_password
    URI.parse(database_url).password
  end

  def self.migrations
    @@migrations
  end

  def self.database_url
    Avram.settings.database_to_migrate.url
  end

  def self.cmd_args
    args = ""
    args += "-U #{self.db_user} " if self.db_user
    args += "-h #{self.db_host} -p #{self.db_port} #{self.db_name}"
  end

  def self.drop_db
    run "dropdb #{self.cmd_args}"
  rescue e : Exception
    if (message = e.message) && message.includes?(%("#{self.db_name}" does not exist))
      puts "Already dropped #{self.db_name.colorize(:green)}"
    else
      raise e
    end
  end

  def self.create_db(quiet? : Bool = false)
    run "createdb #{self.cmd_args}"
    unless quiet?
      puts "Done creating #{Avram::Migrator::Runner.db_name.colorize(:green)}"
    end
  rescue e : Exception
    if (message = e.message) && message.includes?(%("#{self.db_name}" already exists))
      unless quiet?
        puts "Already created #{self.db_name.colorize(:green)}"
      end
    elsif (message = e.message) && (message.includes?("createdb: not found") || message.includes?("No command 'createdb' found"))
      raise <<-ERROR
      #{message}

        #{green_arrow} If you are on macOS  you can install postgres tools from #{macos_postgres_tools_link}
        #{green_arrow} If you are on linux you can try running #{linux_postgres_installation_instructions}
        #{green_arrow} If you are on CI or some servers, there may already be a database created so you don't need this command"
      ERROR
    else
      raise e
    end
  end

  def self.restore_db(restore_file : String, quiet : Bool = false)
    if File.exists?(restore_file)
      run "psql -q #{cmd_args} -v ON_ERROR_STOP=1 < #{restore_file}"
      unless quiet
        puts "Done restoring #{db_name.colorize(:green)}"
      end
    else
      raise "Unable to locate the restore file: #{restore_file}"
    end
  end

  def self.dump_db(quiet : Bool = false)
    run "pg_dump -U #{db_user} -h #{db_host} -p #{db_port} -s #{db_name} > lucky_#{db_name}_dump-#{Time.now.to_s("%Y%m%d%H%I")}.sql"
    unless quiet
      puts "Done dumping #{db_name.colorize(:green)}"
    end
  rescue e : Exception
    message = e.message.to_s
    if message.includes?("does not exist")
      raise <<-ERROR
      The database #{db_name} does not exist on host #{db_host}.

      Try running 'lucky db.create' first.
      ERROR
    elsif message.includes?("Connection refused")
      raise <<-ERROR
      Unable to connect to db #{db_name}.

      Try this...

        ▸ Check your settings in 'config/database.cr'.
        ▸ Run 'luck db.verify_connection' to ensure you can connect
      ERROR
    else
      raise e.message.as(String)
    end
  end

  def self.setup_migration_tracking_tables
    DB.open(database_url) do |db|
      db.exec create_table_for_tracking_migrations
    end
  end

  private def self.create_table_for_tracking_migrations
    <<-SQL
    CREATE TABLE IF NOT EXISTS #{MIGRATIONS_TABLE_NAME} (
      id serial PRIMARY KEY,
      version bigint NOT NULL
    )
    SQL
  end

  private def self.macos_postgres_tools_link
    "https://postgresapp.com/documentation/cli-tools.html".colorize(:green)
  end

  private def self.linux_postgres_installation_instructions
    "sudo apt-get update && sudo apt-get install postgresql postgresql-contrib".colorize(:green)
  end

  def self.run(command : String)
    error_messages = IO::Memory.new
    ENV["PGPASSWORD"] = self.db_password if self.db_password
    result = Process.run command,
      shell: true,
      output: STDOUT,
      error: error_messages
    ENV.delete("PGPASSWORD") if self.db_password
    unless result.success?
      raise error_messages.to_s
    end
  end

  def run_pending_migrations
    prepare_for_migration do
      pending_migrations.each &.new.up(@quiet)
    end
  end

  def run_next_migration
    prepare_for_migration do
      pending_migrations.first.new.up
    end
  end

  def rollback_all
    self.class.setup_migration_tracking_tables
    migrated_migrations.reverse.each &.new.down
  end

  def rollback_one
    self.class.setup_migration_tracking_tables
    if migrated_migrations.empty?
      puts "Did not roll anything back because the database has no migrations.".colorize(:green)
    else
      migrated_migrations.last.new.down
    end
  end

  def rollback_to(last_version : Int64)
    self.class.setup_migration_tracking_tables
    subset = migrated_migrations.select do |mm|
      mm.new.version.to_i64 > last_version
    end
    subset.reverse.each &.new.down
    puts "Done rolling back to #{last_version}".colorize(:green)
  end

  def ensure_migrated!
    if pending_migrations.any?
      raise "There are pending migrations. Please run lucky db.migrate"
    end
  end

  private def migrated_migrations
    @@migrations.select &.new.migrated?
  end

  private def pending_migrations
    @@migrations.select &.new.pending?
  end

  private def prepare_for_migration
    self.class.setup_migration_tracking_tables
    if pending_migrations.empty?
      unless @quiet
        puts "Did not migrate anything because there are no pending migrations.".colorize(:green)
      end
    else
      yield
    end
  rescue e : DB::ConnectionRefused
    raise "Unable to connect to the database. Please check your configuration.".colorize(:red).to_s
  rescue e : Exception
    raise "Unexpected error while running migrations: #{e.message}".colorize(:red).to_s
  end
end
