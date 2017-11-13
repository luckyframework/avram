module LuckyRecord::AllowVirtual
  macro allow_virtual(type_declaration)
    {% if type_declaration.type.is_a?(Union) %}
      {% raise "allow_virtual must use just one type" %}
    {% end %}

    {% type = type_declaration.type %}
    {% name = type_declaration.var %}
    @_{{ name }} : LuckyRecord::Field({{ type }}?)?

    def {{ name }}
      LuckyRecord::AllowedField({{ type }}?).new(_{{ name }})
    end

    private def _{{ name }}
      @_{{ name }} ||= LuckyRecord::Field({{ type }}?).new(
        name: :{{ name }},
        param: {{ name }}_param,
        value: nil,
        form_name: form_name
      ).tap do |field|
        set_{{ name }}_from_param(field)
      end
    end

    private def {{ name }}_param
      params.nested!(form_name)["{{ name }}"]?
    end

    def set_{{ name }}_from_param(field : LuckyRecord::Field)
      parse_result = {{ type }}::Lucky.parse({{ name }}_param)
      if parse_result.is_a? LuckyRecord::Type::SuccessfulCast
        field.value = parse_result.value
      else
        field.add_error "is invalid"
      end
    end
  end
end
