class Avram::SaveOperationTemplate
  macro setup(model_type, columns, table_name, primary_key_type)
    class BaseForm
      macro inherited
        \{% raise "BaseForm has been renamed to SaveOperation. Please inherit from #{model_type}::SaveOperation." %}
      end
    end

    class SaveOperation < Avram::SaveOperation({{ model_type }})
      macro inherited
        FOREIGN_KEY = "{{ model_type.stringify.underscore.id }}_id"
      end

      def table_name
        :{{ table_name }}
      end

      add_column_attributes({{ primary_key_type }}, {{ columns }})
    end
  end
end
