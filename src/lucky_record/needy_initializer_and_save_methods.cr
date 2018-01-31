module LuckyRecord::NeedyInitializerAndSaveMethods
  macro included
    NEEDS_ON_CREATE = [] of Nil
    NEEDS_ON_UPDATE = [] of Nil
    NEEDS_ON_INITIALIZE = [] of Nil

    macro inherited
      inherit_page_settings
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

  macro inherit_page_settings
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
      inherit_page_settings
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
      {% if @type.constant :FIELDS %}
        {% for field in FIELDS %}
          {{ field[:name] }} : {{ field[:type] }} | Nothing{% if field[:nilable] %} | Nil{% end %} = Nothing.new,
        {% end %}
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

      {% if @type.constant :FIELDS %}
        {% for field in FIELDS %}
          unless {{ field[:name] }}.is_a? Nothing
            form.{{ field[:name] }}.value = {{ field[:name] }}
          end
        {% end %}
      {% end %}

      {% if with_bang %}
        form.save!
      {% else %}
        if form.save
          yield form, form.record
        else
          yield form, nil
        end
      {% end %}
    end
  end

  macro generate_update(with_params, with_bang)
    def self.update{% if with_bang %}!{% end %}(
        record,
        {% if with_params %}with params,{% end %}
        {% for type_declaration in (NEEDS_ON_UPDATE + NEEDS_ON_INITIALIZE) %}
          {{ type_declaration }},
        {% end %}
        {% if @type.constant :FIELDS %}
          {% for field in FIELDS %}
            {{ field[:name] }} : {{ field[:type] }} | Nothing{% if field[:nilable] %} | Nil{% end %} = Nothing.new,
          {% end %}
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

      {% if @type.constant :FIELDS %}
        {% for field in FIELDS %}
          unless {{ field[:name] }}.is_a? Nothing
            form.{{ field[:name] }}.value = {{ field[:name] }}
          end
        {% end %}
      {% end %}

      {% if with_bang %}
        form.update!
      {% else %}
        if form.save
          yield form, form.record.not_nil!
        else
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
        params : Hash(String, String) | LuckyRecord::Paramable,
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
      @params = LuckyRecord::Params.new
      extract_changes_from_params
    end

    def initialize(
        @record,
        params : Hash(String, String) | LuckyRecord::Paramable,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          @{{ type_declaration }},
        {% end %}
      )
      @params = ensure_paramable(params)
      extract_changes_from_params
    end

    def initialize(
        @record,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          @{{ type_declaration }},
        {% end %}
      )
      @params = LuckyRecord::Params.new
      extract_changes_from_params
    end
  end
end
