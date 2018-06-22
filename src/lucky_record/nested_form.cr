module LuckyRecord::NestedForm
  macro has_one(type_declaration)
    {% name = type_declaration.var %}
    {% type = type_declaration.type %}
    @_{{ name }} : {{ type }} | Nil

    def {{ name }}
      @_{{ name }} ||= {{ type }}.new(params)
    end

    after_create save_nested_{{ name }}

    def save_nested_{{ name }}(record)
      {{ name }}.{{ @type.constant(:FOREIGN_KEY).id }}.value = record.id

      if !{{ name }}.save
        mark_nested_forms_as_failed
        LuckyRecord::Repo.rollback
      end
    end

    def nested_forms
      {% if @type.methods.map(&.name).includes?(:nested_forms.id) %}
        previous_def +
      {% end %}
      [{{ name }}]
    end
  end

  def mark_nested_forms_as_failed
    nested_forms.each do |f|
      f.mark_as_failed
    end
  end

  def nested_forms
    [] of LuckyRecord::MarkAsFailed
  end
end
