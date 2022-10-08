module Avram::NeedyInitializerAndDeleteMethods
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
      generate_initializer_and_delete_methods
    end
  end

  macro generate_initializer_and_delete_methods
    # Build up a list of method arguments
    #
    # These method arguments can be used in macros for generating delete/new
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

    {% if @type.constant :COLUMN_ATTRIBUTES %}
      {% for attribute in COLUMN_ATTRIBUTES.uniq %}
        {% attribute_method_args = attribute_method_args + "#{attribute[:name]} : #{attribute[:type]} | Avram::Nothing" %}
        {% if attribute[:nilable] %}{% attribute_method_args = attribute_method_args + " | Nil" %}{% end %}
        {% attribute_method_args = attribute_method_args + " = Avram::Nothing.new,\n" %}

        {% attribute_params = attribute_params + "#{attribute[:name]}: #{attribute[:name]},\n" %}
      {% end %}
    {% end %}

    {% for attribute in ATTRIBUTES %}
      {% attribute_method_args = attribute_method_args + "#{attribute.var} : #{attribute.type} | Avram::Nothing = Avram::Nothing.new,\n" %}
      {% attribute_params = attribute_params + "#{attribute.var}: #{attribute.var},\n" %}
    {% end %}

    generate_initializer({{ attribute_method_args }}, {{ attribute_params }})
    generate_delete_methods({{ attribute_method_args }}, {{ attribute_params }})
  end

  macro hash_is_not_allowed_helpful_error(method, additional_args = nil)
    {% raise <<-ERROR
      You can't pass a Hash directly to #{method.id}. Instead pass named arguments, or convert the hash to params.

      Try this...

        * Use named arguments (recommended) - #{@type}.#{method.id}(#{additional_args.id if additional_args}title: "My Title")
        * Convert hash to params (not as safe) - Avram::Params.new({"title" => "My Title"})

      ERROR
    %}
  end

  macro generate_delete(attribute_method_args, attribute_params, with_params, with_bang)
    def self.delete{% if with_bang %}!{% end %}(
      record : T,
      params : Hash,
      **named_args
    )
      {% if with_bang %}
      {% else %}
        yield nil, nil
      {% end %}
      hash_is_not_allowed_helpful_error(:delete{% if with_bang %}!{% end %}, additional_args: "record, ")
    end

    def self.delete{% if with_bang %}!{% end %}(
        record : T,
        {% if with_params %}params,{% end %}
        {% for type_declaration in OPERATION_NEEDS %}
          {{ type_declaration }},
        {% end %}
        {{ attribute_method_args.id }}
      )
      operation = new(
        record,
        {% if with_params %}params,{% end %}
        {% for type_declaration in OPERATION_NEEDS %}
          {{ type_declaration.var }},
        {% end %}
        {{ attribute_params.id }}
      )

      {% if with_bang %}
        operation.delete!
      {% else %}
        operation.delete
        yield operation, operation.record
      {% end %}
    end
  end

  macro generate_delete_methods(attribute_method_args, attribute_params)
    generate_delete({{ attribute_method_args }}, {{ attribute_params }}, with_params: true, with_bang: true)
    generate_delete({{ attribute_method_args }}, {{ attribute_params }}, with_params: true, with_bang: false)
    generate_delete({{ attribute_method_args }}, {{ attribute_params }}, with_params: false, with_bang: true)
    generate_delete({{ attribute_method_args }}, {{ attribute_params }}, with_params: false, with_bang: false)
  end

  macro generate_initializer(attribute_method_args, attribute_params)
    {% needs_method_args = "" %}
    {% for type_declaration in OPERATION_NEEDS %}
      {% needs_method_args = needs_method_args + "@#{type_declaration},\n" %}
    {% end %}

    def initialize(
        @record : T,
        @params : Avram::Paramable,
        {{ needs_method_args.id }}
        {{ attribute_method_args.id }}
      )
      set_attributes({{ attribute_params.id }})
    end

    def initialize(
        @record : T,
        {{ needs_method_args.id }}
        {{ attribute_method_args.id }}
    )
      @params = Avram::Params.new
      set_attributes({{ attribute_params.id }})
    end

    def set_attributes({{ attribute_method_args.id }})
      extract_changes_from_params
      {% if @type.constant :COLUMN_ATTRIBUTES %}
        {% for attribute in COLUMN_ATTRIBUTES.uniq %}
          unless {{ attribute[:name] }}.is_a? Avram::Nothing
            self.{{ attribute[:name] }}.value = {{ attribute[:name] }}
          end
        {% end %}
      {% end %}

      {% for attribute in ATTRIBUTES %}
        unless {{ attribute.var }}.is_a? Avram::Nothing
          self.{{ attribute.var }}.value = {{ attribute.var }}
        end
      {% end %}
    end
  end
end
