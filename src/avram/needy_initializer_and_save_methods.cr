module Avram::NeedyInitializerAndSaveMethods
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

  macro needs(type_declaration, on)
    {% on.raise "The 'on' option is no longer supported. Please use needs without 'on' instead." %}
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
      # @type is not correct in this method, but is in the macro we call below
      # That is why this extrac macro was extracted. We need @type to get the
      # attributes for this SaveOperation
      generate_initializer_and_save_methods
    end
  end

  macro generate_initializer_and_save_methods
    # Build up a list of method arguments
    #
    # These method arguments can be used in macros fro generating create/update/new
    #
    # This way everything has a name and type and we don't have to rely on
    # **named_args. **named_args** are easy but you get horrible type errors.
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

    generate_initializer({{ attribute_method_args }}, {{ attribute_params }})
    generate_save_methods({{ attribute_method_args }}, {{ attribute_params }})
  end

  macro generate_create(attribute_method_args, attribute_params, with_params, with_bang)
    def self.create{% if with_bang %}!{% end %}(
      {% if with_params %}params,{% end %}
      {% for type_declaration in OPERATION_NEEDS %}
        {{ type_declaration }},
      {% end %}
      {{ attribute_method_args.id }}
    )
      operation = new(
        {% if with_params %}params,{% end %}
        {% for type_declaration in OPERATION_NEEDS %}
          {{ type_declaration.var }},
        {% end %}
        {{ attribute_params.id }}
      )

      {% if with_bang %}
        operation.save!
      {% else %}
        if operation.save
          yield operation, operation.record
        else
          operation.published_save_failed_event
          yield operation, nil
        end
      {% end %}
    end
  end

  macro generate_update(attribute_method_args, attribute_params, with_params, with_bang)
    def self.update{% if with_bang %}!{% end %}(
        record : T,
        {% if with_params %}with params,{% end %}
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
        operation.update!
      {% else %}
        if operation.save
          yield operation, operation.record.not_nil!
        else
          operation.published_save_failed_event
          yield operation, operation.record.not_nil!
        end
      {% end %}
    end
  end

  macro generate_save_methods(attribute_method_args, attribute_params)
    generate_create({{ attribute_method_args }}, {{ attribute_params }}, with_params: true, with_bang: false)
    generate_create({{ attribute_method_args }}, {{ attribute_params }}, with_params: true, with_bang: true)
    generate_create({{ attribute_method_args }}, {{ attribute_params }}, with_params: false, with_bang: true)
    generate_create({{ attribute_method_args }}, {{ attribute_params }}, with_params: false, with_bang: false)

    generate_update({{ attribute_method_args }}, {{ attribute_params }}, with_params: true, with_bang: false)
    generate_update({{ attribute_method_args }}, {{ attribute_params }}, with_params: true, with_bang: true)
    generate_update({{ attribute_method_args }}, {{ attribute_params }}, with_params: false, with_bang: true)
    generate_update({{ attribute_method_args }}, {{ attribute_params }}, with_params: false, with_bang: false)
  end

  private class Nothing
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
        @params : Avram::Paramable,
        {{ needs_method_args.id }}
        {{ attribute_method_args.id }}
    )
      @record = nil
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

    def initialize(
        {{ needs_method_args.id }}
        {{ attribute_method_args.id }}
    )
      @record = nil
      @params = Avram::Params.new
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
      extract_changes_from_params
    end
  end
end
