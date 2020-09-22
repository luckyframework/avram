module Avram::DefineAttribute
  macro ensure_base_attributes_method_is_present
    {% if !@type.methods.map(&.name).includes?(:attributes.id) %}
      def attributes
        [] of Avram::PermittedAttribute(Nil)
      end
    {% end %}
  end

  macro included
    ATTRIBUTES = [] of Nil

    macro inherited
      inherit_attributes
    end
  end

  macro inherit_attributes
    \{% if !@type.constant(:ATTRIBUTES) %}
      ATTRIBUTES = [] of Nil
    \{% end %}


    \{% if !@type.ancestors.first.abstract? %}
      \{% for attribute in @type.ancestors.first.constant :ATTRIBUTES %}
        \{% ATTRIBUTES << type_declaration %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_attributes
    end
  end

  ensure_base_attributes_method_is_present

  macro attribute(type_declaration)
    {% if type_declaration.type.is_a?(Union) %}
      {%
        error = "attribute '#{type_declaration.var}' must use just one type. Got #{type_declaration.type}."
        if type_declaration.type.resolve.nilable?
          error = error + "\nNo need to make the type nilable, all attributes have a nil value by default."
        end
        raise error
      %}
    {% end %}

    {% ATTRIBUTES << type_declaration %}

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

    ensure_base_attributes_method_is_present

    def attributes
      ([{{ name }}] + previous_def + super).uniq
    end

    def {{ name }}
      _{{ name }}.permitted
    end

    private def _{{ name }}
      @_{{ name }} ||= Avram::Attribute({{ type }}?).new(
        name: :{{ name }},
        param: {{ name }}_param,
        value: {{ default_value }},
        param_key: self.class.param_key
      ).tap do |attribute|
        if {{ name }}_param_given?
          set_{{ name }}_from_param(attribute)
        end
      end
    end

    private def {{ name }}_param
      params.nested(self.class.param_key)["{{ name }}"]?
    end

    private def {{ name }}_param_given?
      params.nested(self.class.param_key).has_key?("{{ name }}")
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

  macro file_attribute(key)
    {% unless key.is_a?(SymbolLiteral) %}
      {% raise "file_attribute must be declared with a Symbol" %}
    {% end %}

    {% name = key.id %}

    @_{{ name }} : Avram::Attribute(Avram::Uploadable?)?

    ensure_base_attributes_method_is_present

    def attributes
      ([{{ name }}] + previous_def + super).uniq
    end

    def {{ name }}
      _{{ name }}.permitted
    end

    private def _{{ name }}
      @_{{ name }} ||= Avram::Attribute(Avram::Uploadable?).new(
        name: :{{ name }},
        param: {{ name }}_param,
        value: nil,
        param_key: self.class.param_key
      ).tap do |attribute|
        if {{ name }}_param_given?
          set_{{ name }}_from_param(attribute)
        end
      end
    end

    private def {{ name }}_param
      if file = params.nested_file?(self.class.param_key)
        file["{{ name }}"]?
      end
    end

    private def {{ name }}_param_given?
      file = params.nested_file?(self.class.param_key)
      file && file.has_key?("{{ name }}")
    end

    def set_{{ name }}_from_param(attribute : Avram::Attribute)
      parse_result = Avram::Uploadable::Lucky.parse({{ name }}_param)
      if parse_result.is_a? Avram::Type::SuccessfulCast
        attribute.value = parse_result.value
      else
        attribute.add_error "is invalid"
      end
    end
  end
end
