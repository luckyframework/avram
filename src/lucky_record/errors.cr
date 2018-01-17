module LuckyRecord
  # = Lucky Record Errors
  #
  # Generic Lucky Record exception class.
  class LuckyRecordError < Exception
  end

  # Raise to rollback a transaction.
  class Rollback < LuckyRecordError
  end

  # Raised when trying to access a record that was not preloaded and lazy load
  # is disabled.
  class LazyLoadError < LuckyRecordError
    def initialize(model : String, association : String)
      super "#{association} for #{model} must be preloaded with 'preload_#{association}'"
    end
  end

  # Raised when Lucky Record cannot find a record by given id
  class RecordNotFoundError < LuckyRecordError
    def initialize(model : Symbol, id : String)
      super "Could not find #{model} with id of #{id}"
    end

    def initialize(model : Symbol, query : Symbol)
      super "Could not find #{query} record in #{model}"
    end
  end

  # Raised when a validation is expecting an impossible constraint
  class ImpossibleValidation < LuckyRecordError
    def initialize(field : Symbol, message = "an impossible validation")
      super "Validation for #{field} can never satisfy #{message}"
    end
  end

  # Raised when using the create! or update! methods on a form when it does not have the proper attributes
  class InvalidFormError(T) < LuckyRecordError
    getter form

    def initialize(@form : T)
      message = String.build do |message|
        message << "Could not save #{form.class.name}."
        message << "\n"
        message << "\n"
        @form.errors.each do |field_name, errors|
          message << "  ▸ #{field_name}: #{errors.join(", ")}\n"
        end
      end
      super message
    end
  end

  # Raised when an unimplemented or deprecated query is made.
  class UnsupportedQueryError < LuckyRecordError
    def initialize(message : String)
      super message
    end
  end
end
