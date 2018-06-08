module LuckyRecord::Virtual
  macro ensure_base_virtual_fields_method_is_present
    {% if !@type.methods.map(&.name).includes?(:virtual_fields.id) %}
      def virtual_fields
        [] of LuckyRecord::FillableField(Nil)
      end
    {% end %}
  end

  macro included
    VIRTUAL_FIELDS = [] of Nil

    macro inherited
      inherit_virtual_fields
    end
  end

  macro inherit_virtual_fields
    \{% if !@type.constant(:VIRTUAL_FIELDS) %}
      VIRTUAL_FIELDS = [] of Nil
    \{% end %}


    \{% if !@type.ancestors.first.abstract? %}
      \{% for field in @type.ancestors.first.constant :VIRTUAL_FIELDS %}
        \{% VIRTUAL_FIELDS << type_declaration %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_virtual_fields
    end
  end

  ensure_base_virtual_fields_method_is_present

  macro allow_virtual(*args, **named_args)
    {% raise "'allow_virtual' has been renamed to 'virtual'" %}
  end

  macro virtual(type_declaration)
    {% if type_declaration.type.is_a?(Union) %}
      {% raise "virtual must use just one type" %}
    {% end %}

    {% VIRTUAL_FIELDS << type_declaration %}

    {% type = type_declaration.type %}
    {% name = type_declaration.var %}
    @_{{ name }} : LuckyRecord::Field({{ type }}?)?

    ensure_base_virtual_fields_method_is_present

    def virtual_fields
      previous_def + [{{ name }}]
    end

    def {{ name }}
      LuckyRecord::FillableField({{ type }}?).new(_{{ name }})
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
      params.nested(form_name)["{{ name }}"]?
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
