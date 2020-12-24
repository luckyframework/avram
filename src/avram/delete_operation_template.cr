class Avram::DeleteOperationTemplate
  macro setup(type, columns, *args, **named_args)

    # This makes it easy for plugins and extensions to use the base SaveOperation
    def base_query_class : ::{{ type }}::BaseQuery.class
      ::{{ type }}::BaseQuery
    end

    def delete_operation_class : ::{{ type }}::DeleteOperation.class
      ::{{ type }}::DeleteOperation
    end

    class ::{{ type }}::DeleteOperation < Avram::DeleteOperation({{ type }})
      macro inherited
        FOREIGN_KEY = "{{ type.stringify.underscore.id }}_id"
      end

      add_column_attributes({{ columns }})
    end
  end
end
