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
    (URI.parse(Avram::Repo.settings.url).path || "")[1..-1]
  end

  def self.db_host
    URI.parse(Avram::Repo.settings.url).host || "localhost"
  end

  def self.db_port
    URI.parse(Avram::Repo.settings.url).port || "5432"
  end

  def self.db_user
    URI.parse(Avram::Repo.settings.url).user
  end

  def self.db_password
    URI.parse(Avram::Repo.settings.url).password
  end

  def self.migrations
    @@migrations
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
    setup_migration_tracking_tables
    migrated_migrations.reverse.each &.new.down
  end

  def rollback_one
    setup_migration_tracking_tables
    if migrated_migrations.empty?
      puts "Did nothing. No migration to roll back.".colorize(:green)
    else
      migrated_migrations.last.new.down
    end
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

  private def setup_migration_tracking_tables
    DB.open(Avram::Repo.settings.url) do |db|
      db.exec create_table_for_tracking_migrations
    end
  end

  private def prepare_for_migration
    setup_migration_tracking_tables
    if pending_migrations.empty?
      unless @quiet
        puts "Did nothing. No pending migrations.".colorize(:green)
      end
    else
      yield
    end
  rescue e : DB::ConnectionRefused
    raise "Unable to connect to the database. Please check your configuration.".colorize(:red).to_s
  rescue e : Exception
    raise "Unexpected error while running migrations: #{e.message}".colorize(:red).to_s
  end

  private def create_table_for_tracking_migrations
    <<-SQL
    CREATE TABLE IF NOT EXISTS #{MIGRATIONS_TABLE_NAME} (
      id serial PRIMARY KEY,
      version bigint NOT NULL
    )
    SQL
  end
end
