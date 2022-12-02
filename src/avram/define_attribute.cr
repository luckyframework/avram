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
        \{% ATTRIBUTES << attribute %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_attributes
    end
  end

  ensure_base_attributes_method_is_present

  macro attribute(type_declaration)
    {% if type_declaration.type.is_a?(Union) %}
      {% if type_declaration.value.is_a?(Nop) %}
        {% default_value = "" %}
      {% else %}
        {% default_value = "= #{type_declaration.value}" %}
      {% end %}
      {% raise <<-ERROR
        `attribute` in #{@type} must not be called with a type union or nilable type but was called with #{type_declaration.type}
        If you were attempting to create a nilable attribute, all attributes are considered nilable by default.

        Try this...

          attribute #{type_declaration.var} : #{type_declaration.type.types.first} #{default_value.id}

        Read more on attributes: https://luckyframework.org/guides/database/validating-saving
        ERROR
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
    @_{{ name }} : Avram::Attribute({{ type }})?

    ensure_base_attributes_method_is_present

    def attributes
      ([{{ name }}] + previous_def + super).uniq
    end

    def {{ name }}
      _{{ name }}.permitted
    end

    private def _{{ name }}
      @_{{ name }} ||= Avram::Attribute({{ type }}).new(
        name: {{ name.id.symbolize }},
        value: {{ default_value }},
        param_key: self.class.param_key
      ).tap do |attribute|
        attribute.extract(params)
      end
    end
  end

  macro file_attribute(key)
    {% unless key.is_a?(SymbolLiteral) %}
      {% raise "file_attribute must be declared with a Symbol" %}
    {% end %}

    attribute {{ key.id }} : Avram::Uploadable
  end
end
