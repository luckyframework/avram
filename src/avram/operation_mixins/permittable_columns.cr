module Avram::PermittableColumns
  macro permit_columns(*attribute_names)
    {% for attribute_name in attribute_names %}
      {% if attribute_name.is_a?(TypeDeclaration) %}
        {% raise <<-ERROR
          Must use a Symbol or a bare word in 'permit_columns'. Instead, got: #{attribute_name}
          Try this...
            ▸ permit_columns #{attribute_name.var}
          ERROR
        %}
      {% end %}
      {% unless attribute_name.is_a?(SymbolLiteral) || attribute_name.is_a?(Call) %}
        {% raise <<-ERROR
          Must use a Symbol or a bare word in 'permit_columns'. Instead, got: #{attribute_name}
          Try this...
            ▸ Use a bare word (recommended): 'permit_columns name'
            ▸ Use a Symbol: 'permit_columns :name'
          ERROR
        %}
      {% end %}
      {% if COLUMN_ATTRIBUTES.any? { |attribute| attribute[:name].id == attribute_name.id } %}
        def {{ attribute_name.id }}
          _{{ attribute_name.id }}.permitted
        end

        @@permitted_param_keys << "{{ attribute_name.id }}"
      {% else %}
        {% raise <<-ERROR
          Can't permit '#{attribute_name}' because the column has not been defined on the model.
          Try this...
            ▸ Make sure you spelled the column correctly.
            ▸ Add the column to the model if it doesn't exist.
            ▸ Use 'attribute' if you want an attribute that is not saved to the database.
          ERROR
        %}
      {% end %}
    {% end %}
  end
end
