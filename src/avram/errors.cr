module Avram
  # = Lucky Record Errors
  #
  # Generic Lucky Record exception class.
  class AvramError < Exception
  end

  # Raise to rollback a transaction.
  class Rollback < AvramError
  end

  # Raised by Avram::SchemaEnforcer when columns or tables don't match the database.
  class SchemaMismatchError < AvramError
  end

  # Raised when trying to access a record that was not preloaded and lazy load
  # is disabled.
  class LazyLoadError < AvramError
    def initialize(model : String, association : String)
      super "#{association} for #{model} must be preloaded with 'preload_#{association}'"
    end
  end

  # Raised when Lucky Record cannot find a record by given id
  class RecordNotFoundError < AvramError
    def initialize(model : Symbol, id : String)
      super "Could not find #{model} with id of #{id}"
    end

    def initialize(model : Symbol, query : Symbol)
      super "Could not find #{query} record in #{model}"
    end
  end

  # Raised when a validation is expecting an impossible constraint
  class ImpossibleValidation < AvramError
    def initialize(attribute : Symbol, message = "an impossible validation")
      super "Validation for #{attribute} can never satisfy #{message}"
    end
  end

  # Raised when using the create! or update! methods on an operation when it does not have the proper attributes
  class InvalidOperationError < AvramError
    getter errors : Hash(Symbol, Array(String))

    def initialize(operation)
      message = String.build do |string|
        string << "Could not save #{operation.class.name}."
        string << "\n"
        string << "\n"
        operation.errors.each do |attribute_name, errors|
          string << "  ▸ #{attribute_name}: #{errors.join(", ")}\n"
        end
      end
      @errors = operation.errors
      super message
    end

    def save_operation_errors
      {% raise "Avram::InvalidSaveOperationError#save_operation_errors has been renamed to 'errors'" %}
    end
  end

  class InvalidSaveOperationError
    def initialize(*args, **named_args)
      {% raise "#{@type} has been renamed to Avram::InvalidOperationError" %}
    end
  end

  # Raised when an unimplemented or deprecated query is made.
  class UnsupportedQueryError < AvramError
    def initialize(message : String)
      super message
    end
  end

  class ConnectionError < AvramError
    DEFAULT_PG_PORT = 5432

    def initialize(connection_details : URI, database_class : Avram::Database.class)
      error = String.build do |message|
        message << "#{database_class.name}: Failed to connect to database '#{connection_details.path.try(&.[1..-1])}' with username '#{connection_details.user}'.\n"
        message << "Try this..."
        message << '\n'
        message << '\n'
        message << "  ▸ Check connection settings in 'config/database.cr'\n"
        message << "  ▸ Be sure the database exists (lucky db.create)\n"
        message << "  ▸ Check that you have access to connect to #{connection_details.host} on port #{connection_details.port || DEFAULT_PG_PORT}\n"
        if connection_details.password.blank?
          message << "  ▸ You didn't supply a password, did you mean to?\n"
        end
      end
      super error
    end
  end

  class PGClientNotInstalledError < AvramError
    def initialize(original_message : String)
      super <<-ERROR
      Message from Postgres:

        #{original_message}

      Try this...

        ▸ If you are on macOS  you can install postgres tools from #{macos_postgres_tools_link}
        ▸ If you are on linux you can try running #{linux_postgres_installation_instructions}
        ▸ If you are on CI or some servers, there may already be a database created so you don't need this command"


      ERROR
    end

    private def macos_postgres_tools_link
      "https://postgresapp.com/documentation/cli-tools.html".colorize(:green)
    end

    private def linux_postgres_installation_instructions
      "sudo apt-get update && sudo apt-get install postgresql postgresql-contrib".colorize(:green)
    end
  end

  class PGNotRunningError < AvramError
    def initialize(original_message : String)
      super <<-ERROR
      It looks like Postgres is not running.

      Message from Postgres:

        #{original_message}

      Try this...

        ▸ Make sure Postgres is running
        ▸ Check your database configuration settings


      ERROR
    end
  end

  class InvalidDatabaseNameError < AvramError
  end
end
