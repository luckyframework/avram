module Avram::Virtual
  macro ensure_base_virtual_fields_method_is_present
    {% if !@type.methods.map(&.name).includes?(:virtual_fields.id) %}
      def virtual_fields
        [] of Avram::FillableField(Nil)
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
    {%
      default_value = if type_declaration.value.is_a?(Nop)
                        nil
                      else
                        type_declaration.value
                      end
    %}
    @_{{ name }} : Avram::Field({{ type }}?)?

    ensure_base_virtual_fields_method_is_present

    def virtual_fields
      previous_def + [{{ name }}]
    end

    def {{ name }}
      _{{ name }}.fillable
    end

    private def _{{ name }}
      @_{{ name }} ||= Avram::Field({{ type }}?).new(
        name: :{{ name }},
        param: {{ name }}_param,
        value: {{ default_value }},
        form_name: form_name
      ).tap do |field|
        if {{ name }}_param_given?
          set_{{ name }}_from_param(field)
        end
      end
    end

    private def {{ name }}_param
      params.nested(form_name)["{{ name }}"]?
    end

    private def {{ name }}_param_given?
      params.nested(form_name).has_key?("{{ name }}")
    end

    def set_{{ name }}_from_param(field : Avram::Field)
      parse_result = {{ type }}::Lucky.parse({{ name }}_param)
      if parse_result.is_a? Avram::Type::SuccessfulCast
        field.value = parse_result.value
      else
        field.add_error "is invalid"
      end
    end
  end
end
