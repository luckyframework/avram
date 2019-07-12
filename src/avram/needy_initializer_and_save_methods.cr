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
      {% if @type.constant :COLUMN_ATTRIBUTES %}
        {% for attribute in COLUMN_ATTRIBUTES.uniq %}
          {{ attribute[:name] }} : {{ attribute[:type] }} | Nothing{% if attribute[:nilable] %} | Nil{% end %} = Nothing.new,
        {% end %}
      {% end %}
      {% for attribute in ATTRIBUTES %}
        {{ attribute.var }} : {{ attribute.type }} | Nothing = Nothing.new,
      {% end %}
    )
      form = new(
        {% if with_params %}params,{% end %}
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_CREATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}

      {% if @type.constant :COLUMN_ATTRIBUTES %}
        {% for attribute in COLUMN_ATTRIBUTES.uniq %}
          unless {{ attribute[:name] }}.is_a? Nothing
            form.{{ attribute[:name] }}.value = {{ attribute[:name] }}
          end
        {% end %}
      {% end %}

      {% for attribute in ATTRIBUTES %}
        unless {{ attribute.var }}.is_a? Nothing
          form.{{ attribute.var }}.value = {{ attribute.var }}
        end
      {% end %}

      {% if with_bang %}
        form.save!
      {% else %}
        if form.save
          yield form, form.record
        else
          form.log_failed_save
          yield form, nil
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
        {% if @type.constant :COLUMN_ATTRIBUTES %}
          {% for attribute in COLUMN_ATTRIBUTES.uniq %}
            {{ attribute[:name] }} : {{ attribute[:type] }} | Nothing{% if attribute[:nilable] %} | Nil{% end %} = Nothing.new,
          {% end %}
        {% end %}
        {% for attribute in ATTRIBUTES %}
          {{ attribute.var }} : {{ attribute.type }} | Nothing = Nothing.new,
        {% end %}
      )
      form = new(
        record,
        {% if with_params %}params,{% end %}
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_UPDATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}

      {% if @type.constant :COLUMN_ATTRIBUTES %}
        {% for attribute in COLUMN_ATTRIBUTES.uniq %}
          unless {{ attribute[:name] }}.is_a? Nothing
            form.{{ attribute[:name] }}.value = {{ attribute[:name] }}
          end
        {% end %}
      {% end %}

      {% for attribute in ATTRIBUTES %}
        unless {{ attribute.var }}.is_a? Nothing
          form.{{ attribute.var }}.value = {{ attribute.var }}
        end
      {% end %}

      {% if with_bang %}
        form.update!
      {% else %}
        if form.save
          yield form, form.record.not_nil!
        else
          form.log_failed_save
          yield form, form.record.not_nil!
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

  class Nothing
  end

  macro generate_initializer
    def initialize(
        params : Hash(String, String) | Avram::Paramable,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          @{{ type_declaration }},
        {% end %}
      )
      @params = ensure_paramable(params)
      extract_changes_from_params
    end

    def initialize(
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          @{{ type_declaration }},
        {% end %}
      )
      @params = Avram::Params.new
      extract_changes_from_params
    end

    def initialize(
        @record : T,
        params : Hash(String, String) | Avram::Paramable,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          @{{ type_declaration }},
        {% end %}
      )
      @params = ensure_paramable(params)
      extract_changes_from_params
    end

    def initialize(
        @record : T,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          @{{ type_declaration }},
        {% end %}
      )
      @params = Avram::Params.new
      extract_changes_from_params
    end
  end
end
