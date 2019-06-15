module Avram
  # = Lucky Record Errors
  #
  # Generic Lucky Record exception class.
  class AvramError < Exception
  end

  # Raise to rollback a transaction.
  class Rollback < AvramError
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
    def initialize(field : Symbol, message = "an impossible validation")
      super "Validation for #{field} can never satisfy #{message}"
    end
  end

  # Raised when using the create! or update! methods on a form when it does not have the proper attributes
  class InvalidSaveOperationError < AvramError
    getter save_operation_errors : Hash(Symbol, Array(String))

    def initialize(form)
      message = String.build do |message|
        message << "Could not save #{form.class.name}."
        message << "\n"
        message << "\n"
        form.errors.each do |field_name, errors|
          message << "  ▸ #{field_name}: #{errors.join(", ")}\n"
        end
      end
      @save_operation_errors = form.errors
      super message
    end
  end

  # Raised when an unimplemented or deprecated query is made.
  class UnsupportedQueryError < AvramError
    def initialize(message : String)
      super message
    end
  end

  class ConnectionError < AvramError
    def initialize(connection_details : URI)
      error = String.build do |message|
        message << "Failed to connect to databse '#{connection_details.path.try(&.[1..-1])}' with username '#{connection_details.user}'.\n"
        message << "Try this..."
        message << '\n'
        message << '\n'
        message << "  ▸ Check connection settings in 'config/database.cr'\n"
        message << "  ▸ Be sure the database exists (lucky db.create)\n"
        message << "  ▸ Check that you have access to connect to #{connection_details.host} on port #{connection_details.port}\n"
        if connection_details.password.blank?
          message << "  ▸ You didn't supply a password, did you mean to?\n"
        end
      end
      super error
    end
  end
end
