module Avram::FormErrors
  def errors
    fields.reduce({} of Symbol => Array(String)) do |errors_hash, field|
      if field.errors.empty?
        errors_hash
      else
        errors_hash[field.name] = field.errors
        errors_hash
      end
    end
  end
end
