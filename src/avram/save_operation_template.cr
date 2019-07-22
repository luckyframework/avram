class Avram::SaveOperationTemplate
  macro setup(type, columns, table_name, primary_key_type, primary_key_name, *args, **named_args)
    class ::{{ type }}::BaseForm
      macro inherited
        \{% raise "BaseForm has been renamed to SaveOperation. Please inherit from #{type}::SaveOperation." %}
      end
    end

    class ::{{ type }}::SaveOperation < Avram::SaveOperation({{ type }})
      {% if primary_key_type.id == UUID.id %}
        before_save set_uuid

        def set_uuid
          id.value ||= UUID.random()
        end
      {% end %}

      def database
        {{ type }}.database
      end

      macro inherited
        FOREIGN_KEY = "{{ type.stringify.underscore.id }}_id"
      end

      def table_name
        :{{ table_name }}
      end

      def primary_key_name
        :{{ primary_key_name.id }}
      end

      add_column_attributes({{ primary_key_type }}, {{ columns }})
    end
  end
end
