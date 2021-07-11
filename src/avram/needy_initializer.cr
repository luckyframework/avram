module Avram::NeedyInitializer
  macro included
    OPERATION_NEEDS = [] of Nil

    macro inherited
      inherit_needs
    end
  end

  macro needs(type_declaration)
    {% OPERATION_NEEDS << type_declaration %}
    property {{ type_declaration.var }} : {{ type_declaration.type }}
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
      # This is called at the end so @type will be of the subclass,
      # and not the parent abstract class.
      generate_initializers
    end
  end

  macro generate_initializers
    # Build up a list of method arguments
    #
    # This way everything has a name and type and we don't have to rely on
    # **named_args. **named_args** are easy but you get horrible type errors.
    #
    # attribute_method_args would look something like:
    #
    #   name : String | Avram::Nothing = Avram::Nothing.new,
    #   email : String | Nil | Avram::Nothing = Avram::Nothing.new
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

    {% for attribute in ATTRIBUTES %}
      {% attribute_method_args = attribute_method_args + "#{attribute.var} : #{attribute.type} | Avram::Nothing = Avram::Nothing.new,\n" %}
      {% attribute_params = attribute_params + "#{attribute.var}: #{attribute.var},\n" %}
    {% end %}

    generate_initializer({{ attribute_method_args }}, {{ attribute_params }})
  end

  macro generate_initializer(attribute_method_args, attribute_params)
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

    def initialize(
        {{ needs_method_args.id }}
        {{ attribute_method_args.id }}
    )
      @params = Avram::Params.new
      set_attributes({{ attribute_params.id }})
    end

    def set_attributes({{ attribute_method_args.id }})
      {% for attribute in ATTRIBUTES %}
        unless {{ attribute.var }}.is_a? Avram::Nothing
          self.{{ attribute.var }}.value = {{ attribute.var }}
        end
      {% end %}
    end
  end
end
