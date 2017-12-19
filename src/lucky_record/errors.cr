module LuckyRecord
  # = Lucky Record Errors
  #
  # Generic Lucky Record exception class.
  class LuckyRecordError < Exception
  end

  # Raised when a record could not be found
  class RecordNotFoundError < LuckyRecordError
    def initialize(model : Symbol, id : String)
      super "Could not find #{model} with id of #{id}"
    end

    def initialize(model : Symbol, query : Symbol)
      super "Could not find #{query} record in #{model}"
    end
  end

  # Raised when using the save! or update! methods on a form when it does not have the proper attributes
  class InvalidFormError(T) < LuckyRecordError
    getter form_name
    getter form_object

    def initialize(@form_name : String, @form_object : T)
      super "Invalid #{form_name}. Could not save #{@form_object}"
    end
  end

  # Raised when an unimplemented or deprecated query is made.
  class UnsupportedQueryError < LuckyRecordError
    def initialize(message : String)
      super message
    end
  end
end
