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

  macro allow_virtual(*args, **named_args)
    {% raise "'allow_virtual' has been renamed to 'attribute'" %}
  end

  macro virtual(*args, **named_args)
    {% raise "'virtual' has been renamed to 'attribute'" %}
  end

  macro attribute(type_declaration)
    {% if type_declaration.type.is_a?(Union) %}
      {% raise "attribute must use just one type" %}
    {% end %}

    {% ATTRIBUTES << type_declaration %}

    {%
      target_type = type_declaration.type

      includers = Avram::Uploadable.includers
      includers.each { |includer| includers += includer.all_subclasses }
      is_uploadable = includers.includes?(target_type.resolve)

      type = is_uploadable ? Avram::Uploadable : target_type
      name = type_declaration.var

      default_value = if type_declaration.value.is_a?(Nop) || is_uploadable
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
      {% if is_uploadable %}
        if file = params.nested_file?(self.class.param_key)
          file["{{ name }}"]?
        end
      {% else %}
        params.nested(self.class.param_key)["{{ name }}"]?
      {% end %}
    end

    private def {{ name }}_param_given?
      {% if is_uploadable %}
        file = params.nested_file?(self.class.param_key)
        file && file.has_key?("{{ name }}")
      {% else %}
        params.nested(self.class.param_key).has_key?("{{ name }}")
      {% end %}
    end

    def set_{{ name }}_from_param(attribute : Avram::Attribute)
      parse_result = {{ type }}::Lucky.parse({{ name }}_param)
      if parse_result.is_a? Avram::Type::SuccessfulCast
        {% if is_uploadable %}
          attribute.value = if parse_result.value.class == {{ target_type }}
                              parse_result.value
                            else
                              {{ target_type }}.new(parse_result.value)
                            end
        {% else %}
          attribute.value = parse_result.value
        {% end %}
      else
        attribute.add_error "is invalid"
      end
    end
  end
end
