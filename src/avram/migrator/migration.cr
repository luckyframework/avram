require "colorize"
require "./*"

abstract class Avram::Migrator::Migration::V1
  include Avram::Migrator::StatementHelpers

  alias MigrationId = Int32 | Int64

  macro inherited
    Avram::Migrator::Runner.migrations << self

    def version : Int64
      get_version_from_filename.to_i64
    end

    macro get_version_from_filename
      {{@type.name.split("::").last.gsub(/V/, "")}}
    end
  end

  abstract def migrate
  abstract def version : Int64

  getter prepared_statements = [] of String

  # Unless already migrated, calls migrate which in turn calls statement
  # helpers to generate and collect SQL statements in the
  # @prepared_statements array. Each statement is then executed in  a
  # transaction and tracked upon completion.
  def up(quiet = false)
    suppress_logging do
      if migrated?
        puts "Already migrated #{self.class.name.colorize(:cyan)}"
      else
        reset_prepared_statements
        migrate
        execute_in_transaction @prepared_statements do |txn|
          track_migration(txn)
          unless quiet
            puts "Migrated #{self.class.name.colorize(:green)}"
          end
        end
      end
    end
  end

  # Same as #up except calls rollback method in migration.
  def down(quiet = false)
    suppress_logging do
      if pending?
        puts "Already rolled back #{self.class.name.colorize(:cyan)}"
      else
        reset_prepared_statements
        rollback
        execute_in_transaction @prepared_statements do |txn|
          untrack_migration(txn)
          unless quiet
            puts "Rolled back #{self.class.name.colorize(:green)}"
          end
        end
      end
    end
  end

  def pending?
    !migrated?
  end

  def migrated?
    suppress_logging do
      Avram.settings
        .database_to_migrate
        .query_one? "SELECT id FROM migrations WHERE version = $1", version, as: MigrationId
    end
  end

  private def track_migration(db : Avram::Database.class)
    db.exec "INSERT INTO migrations(version) VALUES ($1)", version
  end

  private def untrack_migration(db : Avram::Database.class)
    db.exec "DELETE FROM migrations WHERE version = $1", version
  end

  private def execute(statement : String)
    @prepared_statements << statement
  end

  # Accepts an array of SQL statements and a block. Iterates through the
  # array, running each statement in a transaction then yields the block
  # with the transaction as an argument.
  #
  # # Usage
  #
  # ```
  # execute_in_transaction ["DROP TABLE comments;"] do |db|
  #   db.exec "DROP TABLE users;"
  # end
  # ```
  private def execute_in_transaction(statements : Array(String), &)
    database = Avram.settings.database_to_migrate
    database.transaction do
      statements.each { |sql| database.exec sql }
      yield database
    end
  rescue e : PQ::PQError
    raise FailedMigration.new(migration: self.class.name, statements: statements, cause: e)
  end

  def reset_prepared_statements
    @prepared_statements = [] of String
  end

  private def suppress_logging(&)
    Avram::QueryLog.dexter.temp_config(level: :none) do
      return yield
    end
  end
end
