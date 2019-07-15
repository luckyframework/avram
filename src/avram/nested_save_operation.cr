module Avram::NestedSaveOperation
  macro has_one(type_declaration)
    {% name = type_declaration.var %}
    {% type = type_declaration.type %}
    @_{{ name }} : {{ type }} | Nil

    def {{ name }}
      @_{{ name }} ||= {{ type }}.new(params)
    end

    after_save save_nested_{{ name }}

    def save_nested_{{ name }}(record)
      {{ name }}.{{ @type.constant(:FOREIGN_KEY).id }}.value = record.id

      if !{{ name }}.save
        mark_nested_save_operations_as_failed
        database.rollback
      end
    end

    def nested_save_operations
      {% if @type.methods.map(&.name).includes?(:nested_save_operations.id) %}
        previous_def +
      {% end %}
      [{{ name }}]
    end
  end

  def mark_nested_save_operations_as_failed
    nested_save_operations.each do |f|
      f.mark_as_failed
    end
  end

  def nested_save_operations
    [] of Avram::MarkAsFailed
  end
end
