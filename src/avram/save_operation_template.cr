class Avram::SaveOperationTemplate
  macro setup(type, columns, *args, **named_args)

    # This makes it easy for plugins and extensions to use the base SaveOperation
    def base_query_class : ::{{ type }}::BaseQuery.class
      ::{{ type }}::BaseQuery
    end

    def save_operation_class : ::{{ type }}::SaveOperation.class
      ::{{ type }}::SaveOperation
    end

    class ::{{ type }}::SaveOperation < Avram::SaveOperation({{ type }})
      {% primary_key_type = type.resolve.constant("PRIMARY_KEY_TYPE") %}
      {% if primary_key_type.id == UUID.id %}
        before_save set_uuid

        def set_uuid
          {% primary_key_name = type.resolve.constant("PRIMARY_KEY_NAME") %}
          {{ primary_key_name.id }}.value ||= UUID.random()
        end
      {% end %}

      macro inherited
        FOREIGN_KEY = "{{ type.stringify.underscore.id }}_id"
      end

      add_column_attributes({{ columns }})
      add_cast_value_methods({{ columns }})
    end
  end
end
