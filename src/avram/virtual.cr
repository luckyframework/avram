module Avram::Virtual
  macro ensure_base_virtual_attributes_method_is_present
    {% if !@type.methods.map(&.name).includes?(:virtual_attributes.id) %}
      def virtual_attributes
        [] of Avram::FillableAttribute(Nil)
      end
    {% end %}
  end

  macro included
    VIRTUAL_ATTRIBUTES = [] of Nil

    macro inherited
      inherit_virtual_attributes
    end
  end

  macro inherit_virtual_attributes
    \{% if !@type.constant(:VIRTUAL_ATTRIBUTES) %}
      VIRTUAL_ATTRIBUTES = [] of Nil
    \{% end %}


    \{% if !@type.ancestors.first.abstract? %}
      \{% for attribute in @type.ancestors.first.constant :VIRTUAL_ATTRIBUTES %}
        \{% VIRTUAL_ATTRIBUTES << type_declaration %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_virtual_attributes
    end
  end

  ensure_base_virtual_attributes_method_is_present

  macro allow_virtual(*args, **named_args)
    {% raise "'allow_virtual' has been renamed to 'virtual'" %}
  end

  macro virtual(type_declaration)
    {% if type_declaration.type.is_a?(Union) %}
      {% raise "virtual must use just one type" %}
    {% end %}

    {% VIRTUAL_ATTRIBUTES << type_declaration %}

    {% type = type_declaration.type %}
    {% name = type_declaration.var %}
    {%
      default_value = if type_declaration.value.is_a?(Nop)
                        nil
                      else
                        type_declaration.value
                      end
    %}
    @_{{ name }} : Avram::Attribute({{ type }}?)?

    ensure_base_virtual_attributes_method_is_present

    def virtual_attributes
      previous_def + [{{ name }}]
    end

    def {{ name }}
      _{{ name }}.fillable
    end

    private def _{{ name }}
      @_{{ name }} ||= Avram::Attribute({{ type }}?).new(
        name: :{{ name }},
        param: {{ name }}_param,
        value: {{ default_value }},
        form_name: form_name
      ).tap do |attribute|
        if {{ name }}_param_given?
          set_{{ name }}_from_param(attribute)
        end
      end
    end

    private def {{ name }}_param
      params.nested(form_name)["{{ name }}"]?
    end

    private def {{ name }}_param_given?
      params.nested(form_name).has_key?("{{ name }}")
    end

    def set_{{ name }}_from_param(attribute : Avram::Attribute)
      parse_result = {{ type }}::Lucky.parse({{ name }}_param)
      if parse_result.is_a? Avram::Type::SuccessfulCast
        attribute.value = parse_result.value
      else
        attribute.add_error "is invalid"
      end
    end
  end
end
