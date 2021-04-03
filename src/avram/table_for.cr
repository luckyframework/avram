module Avram::TableFor
  # Returns a `Symbol` representing the table name
  # of the `model` passed in.
  # e.g. `User` => `:users`
  macro table_for(model)
    Wordsmith::Inflector.pluralize({{ model.stringify }}.gsub("::", "").underscore)
  end
end
