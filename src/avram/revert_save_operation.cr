module Avram::RevertSaveOperation
  macro included
    macro inherited
      generate_revert_methods
    end
  end

  macro generate_revert_methods
    def revert : self
      if persisted?
        operation = \{% begin %}self.class.new(
          record.not_nil!,
          \{% for need in OPERATION_NEEDS %}
            \{{ need.var }}: \{{ need.var }},
          \{% end %}
        )\{% end %}
      else
        operation = \{% begin %}self.class.new(
          \{% for need in OPERATION_NEEDS %}
            \{{ need.var }}: \{{ need.var }},
          \{% end %}
        )\{% end %}

        operation.add_error(:revert, "No record to revert")
        return operation
      end

      unless saved?
        operation.add_error(:revert, "Cannot revert an unsaved record")
        return operation
      end

      if new_record?
        revert_create(operation)
      else
        revert_update(operation)
      end

      operation
    end

    def revert! : self
      operation = revert
      return operation if operation.valid?
      raise Avram::InvalidOperationError.new(operation: operation)
    end

    private def revert_create(operation)
      if record.not_nil!.delete.rows_affected < 1
        operation.add_error(:revert, "Could not delete record")
      end
    end

    private def revert_update(operation)
      \{% for attribute in ATTRIBUTES %}
        operation.\{{ attribute.var }}.value =
          \{{ attribute.var }}.original_value
      \{% end %}

      \{% if @type.constant(:COLUMN_ATTRIBUTES) %}
        \{% for column in COLUMN_ATTRIBUTES.uniq %}
          operation.\{{ column[:name].id }}.value =
            \{{ column[:name].id }}.original_value
        \{% end %}
      \{% end %}

      unless operation.save
        operation.add_error(:revert, "Could not update record")
      end
    end

    macro inherited
      generate_revert_methods
    end
  end
end
