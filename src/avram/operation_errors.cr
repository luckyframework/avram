module Avram::OperationErrors
  macro included
    @custom_errors : Hash(Symbol, Array(String)) = {} of Symbol => Array(String)
    getter :custom_errors
  end

  def errors : Hash(Symbol, Array(String))
    attr_errors = attributes.reduce({} of Symbol => Array(String)) do |errors_hash, attribute|
      if attribute.errors.empty?
        errors_hash
      else
        errors_hash[attribute.name] = attribute.errors
        errors_hash
      end
    end

    attr_errors.merge(@custom_errors)
  end

  def add_error(key : Symbol, message : String) : Nil
    @custom_errors[key] ||= [] of String
    @custom_errors[key].push(message)
  end
end
