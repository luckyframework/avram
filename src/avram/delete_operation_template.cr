class Avram::DeleteOperationTemplate
  macro setup(type, columns, *args, **named_args)

    def delete_operation_class : ::{{ type }}::DeleteOperation.class
      ::{{ type }}::DeleteOperation
    end

    class ::{{ type }}::DeleteOperation < Avram::DeleteOperation({{ type }})

      add_column_attributes({{ columns }})
    end
  end
end
