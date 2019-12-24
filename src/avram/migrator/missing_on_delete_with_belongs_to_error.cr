module Avram::Migrator::MissingOnDeleteWithBelongsToError
  macro add_belongs_to(type_declaration, references = nil)
    {% raise <<-ERROR
      Must use 'on_delete' with 'add_belongs_to'

      Try this...

        ▸ add_belongs_to #{type_declaration}, on_delete: :cascade

      You can also use :restrict, :nullify, or :do_nothing

      Read more at: https://luckyframework.org/guides/database/migrations#associations


      ERROR
    %}
  end
end
