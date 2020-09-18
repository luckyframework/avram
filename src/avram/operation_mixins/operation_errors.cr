module Avram::OperationErrors
  class Avram::FailedOperation < Exception
  end

  def errors : Hash(Symbol, Array(String))
    attributes.reduce({} of Symbol => Array(String)) do |errors_hash, attribute|
      if attribute.errors.empty?
        errors_hash
      else
        errors_hash[attribute.name] = attribute.errors
        errors_hash
      end
    end
  end
end
