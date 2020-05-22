module Avram::NeedyInitializer
  macro included
    OPERATION_NEEDS = [] of Nil

    macro inherited
      inherit_needs
    end
  end

  macro needs(type_declaration)
    {% OPERATION_NEEDS << type_declaration %}
    @{{ type_declaration.var }} : {{ type_declaration.type }}
    property {{ type_declaration.var }}
  end

  macro inherit_needs
    \{% if !@type.constant(:OPERATION_NEEDS) %}
      OPERATION_NEEDS = [] of Nil
    \{% end %}

    \{% if !@type.ancestors.first.abstract? %}
      \{% for type_declaration in @type.ancestors.first.constant :OPERATION_NEEDS %}
        \{% OPERATION_NEEDS << type_declaration %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_needs
    end

    macro finished
      setup_initializer
    end
  end

  macro setup_initializer
    # Build up a list of method arguments
    #
    # This way everything has a name and type and we don't have to rely on
    # **named_args**. **named_args** are easy but you get horrible type errors.
    #
    # attribute_method_args would look something like:
    #
    #   name : String | Nothing = Nothing.new,
    #   email : String | Nil | Nothing = Nothing.new
    #
    # This can be passed to macros as a string, and then the macro can call .id
    # on it to output the string as code!
    {% attribute_method_args = "" %}

    # Build up a list of params so you can use the method args
    #
    # This looks something like:
    #
    #   name: name,
    #   email: email
    {% attribute_params = "" %}

    {% if @type.constant :COLUMN_ATTRIBUTES %}
      {% for attribute in COLUMN_ATTRIBUTES.uniq %}
        {% attribute_method_args = attribute_method_args + "#{attribute[:name]} : #{attribute[:type]} | Nothing" %}
        {% if attribute[:nilable] %}{% attribute_method_args = attribute_method_args + " | Nil" %}{% end %}
        {% attribute_method_args = attribute_method_args + " = Nothing.new,\n" %}

        {% attribute_params = attribute_params + "#{attribute[:name]}: #{attribute[:name]},\n" %}
      {% end %}
    {% end %}

    {% for attribute in ATTRIBUTES %}
      {% attribute_method_args = attribute_method_args + "#{attribute.var} : #{attribute.type} | Nothing = Nothing.new,\n" %}
      {% attribute_params = attribute_params + "#{attribute.var}: #{attribute.var},\n" %}
    {% end %}

    generate_initializers({{ attribute_method_args }}, {{ attribute_params }})
  end

  private class Nothing
  end

  macro generate_initializers(attribute_method_args, attribute_params)
    {% needs_method_args = "" %}
    {% for type_declaration in OPERATION_NEEDS %}
      {% needs_method_args = needs_method_args + "@#{type_declaration},\n" %}
    {% end %}

    def initialize(
        @params : Avram::Paramable,
        {{ needs_method_args.id }}
        {{ attribute_method_args.id }}
      )
      set_attributes({{ attribute_params.id }})
    end

    def set_attributes({{ attribute_method_args.id }})
      {% if @type.constant :COLUMN_ATTRIBUTES %}
        {% for attribute in COLUMN_ATTRIBUTES.uniq %}
          unless {{ attribute[:name] }}.is_a? Nothing
            self.{{ attribute[:name] }}.value = {{ attribute[:name] }}
          end
        {% end %}
      {% end %}

      {% for attribute in ATTRIBUTES %}
        unless {{ attribute.var }}.is_a? Nothing
          self.{{ attribute.var }}.value = {{ attribute.var }}
        end
      {% end %}
    end
  end
end