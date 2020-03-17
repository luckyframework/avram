module Avram::NeedyInitializerAndSaveMethods
  macro included
    NEEDS_ON_CREATE = [] of Nil
    NEEDS_ON_UPDATE = [] of Nil
    NEEDS_ON_INITIALIZE = [] of Nil

    macro inherited
      inherit_needs
    end

    generate_initializer
  end

  macro needs(type_declaration)
    {% NEEDS_ON_INITIALIZE << type_declaration %}
    @{{ type_declaration.var }} : {{ type_declaration.type }}
    property {{ type_declaration.var }}
  end

  macro needs(type_declaration, on)
    {% if ![:save, :create, :update].includes?(on) %}
      {% raise "on option must be :save, :create or :update" %}
    {% end %}
    {% if on == :save %}
      {% NEEDS_ON_UPDATE << type_declaration %}
      {% NEEDS_ON_CREATE << type_declaration %}
    {% elsif on == :update %}
      {% NEEDS_ON_UPDATE << type_declaration %}
    {% else %}
      {% NEEDS_ON_CREATE << type_declaration %}
    {% end %}
    @{{ type_declaration.var }} : {{ type_declaration.type }}?
    property {{ type_declaration.var }}
  end

  macro inherit_needs
    \{% if !@type.constant(:NEEDS_ON_CREATE) %}
      NEEDS_ON_CREATE = [] of Nil
      NEEDS_ON_UPDATE = [] of Nil
      NEEDS_ON_INITIALIZE = [] of Nil
    \{% end %}

    \{% if !@type.ancestors.first.abstract? %}
      \{% for type_declaration in @type.ancestors.first.constant :NEEDS_ON_CREATE %}
        \{% NEEDS_ON_CREATE << type_declaration %}
      \{% end %}
      \{% for type_declaration in @type.ancestors.first.constant :NEEDS_ON_UPDATE %}
        \{% NEEDS_ON_UPDATE << type_declaration %}
      \{% end %}
      \{% for type_declaration in @type.ancestors.first.constant :NEEDS_ON_INITIALIZE %}
        \{% NEEDS_ON_INITIALIZE << type_declaration %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_needs
    end

    macro finished
      generate_initializer
      generate_save_methods
    end
  end

  macro generate_create(with_params, with_bang)
    def self.create{% if with_bang %}!{% end %}(
      {% if with_params %}params,{% end %}
      {% for type_declaration in (NEEDS_ON_CREATE + NEEDS_ON_INITIALIZE) %}
        {{ type_declaration }},
      {% end %}
      **named_args
    )
      operation = new(
        {% if with_params %}params,{% end %}
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
        **named_args
      )
      {% for type_declaration in NEEDS_ON_CREATE %}
        operation.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}

      {% if with_bang %}
        operation.save!
      {% else %}
        if operation.save
          yield operation, operation.record
        else
          operation.log_failed_save
          yield operation, nil
        end
      {% end %}
    end
  end

  macro generate_update(with_params, with_bang)
    def self.update{% if with_bang %}!{% end %}(
        record : T,
        {% if with_params %}with params,{% end %}
        {% for type_declaration in (NEEDS_ON_UPDATE + NEEDS_ON_INITIALIZE) %}
          {{ type_declaration }},
        {% end %}
        **named_args
      )
      operation = new(
        record,
        {% if with_params %}params,{% end %}
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
        **named_args
      )
      {% for type_declaration in NEEDS_ON_UPDATE %}
        operation.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}

      {% if with_bang %}
        operation.update!
      {% else %}
        if operation.save
          yield operation, operation.record.not_nil!
        else
          operation.log_failed_save
          yield operation, operation.record.not_nil!
        end
      {% end %}
    end
  end

  macro generate_save_methods
    generate_create(with_params: true, with_bang: false)
    generate_create(with_params: true, with_bang: true)
    generate_create(with_params: false, with_bang: true)
    generate_create(with_params: false, with_bang: false)

    generate_update(with_params: true, with_bang: false)
    generate_update(with_params: true, with_bang: true)
    generate_update(with_params: false, with_bang: true)
    generate_update(with_params: false, with_bang: false)
  end

  private class Nothing
  end

  macro generate_initializer
    def initialize(
        @record : T? = nil,
        @params : Avram::Paramable = Avram::Params.new,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          @{{ type_declaration }},
        {% end %}
        **named_args
      )
      set_attributes(**named_args)
      extract_changes_from_params
    end

    def initialize(
        @params : Avram::Paramable = Avram::Params.new,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          @{{ type_declaration }},
        {% end %}
        **named_args
    )
      @record = nil
      set_attributes(**named_args)
      extract_changes_from_params
    end

    def set_attributes(
      {% if @type.constant :COLUMN_ATTRIBUTES %}
        {% for attribute in COLUMN_ATTRIBUTES.uniq %}
          {{ attribute[:name] }} : {{ attribute[:type] }} | Nothing{% if attribute[:nilable] %} | Nil{% end %} = Nothing.new,
        {% end %}
      {% end %}
      {% for attribute in ATTRIBUTES %}
        {{ attribute.var }} : {{ attribute.type }} | Nothing = Nothing.new,
      {% end %}
    )
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
