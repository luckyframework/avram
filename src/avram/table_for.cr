module Avram::TableFor
  # Returns a `Symbol` representing the table name
  # of the `model` passed in.
  # e.g. `User` => `:users`
  macro table_for(model)
    :{{ run("../run_macros/infer_table_name.cr", model.id) }}
  end
end
