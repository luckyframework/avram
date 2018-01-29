module LuckyRecord::NeedyInitializer
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

  macro generate_save_methods
    def self.create(
      params,
      {% for type_declaration in (NEEDS_ON_CREATE + NEEDS_ON_INITIALIZE) %}
        {{ type_declaration }},
      {% end %}
    )
      form = new(
        params,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_CREATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}
      if form.save
        yield form, form.record
      else
        yield form, nil
      end
    end

    def self.create(
      {% for type_declaration in (NEEDS_ON_CREATE + NEEDS_ON_INITIALIZE) %}
        {{ type_declaration }},
      {% end %}
    )
      form = new(
        LuckyRecord::Params.new,
        {% for type_declaration in NEEDS_ON_CREATE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_CREATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}
      if form.save
        yield form, form.record
      else
        yield form, nil
      end
    end

    def self.create!(
      params,
      {% for type_declaration in (NEEDS_ON_CREATE + NEEDS_ON_INITIALIZE) %}
        {{ type_declaration }},
      {% end %}
    )
      form = new(
        params,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_CREATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}
      form.save!
    end

    def self.create!(
      {% for type_declaration in (NEEDS_ON_CREATE + NEEDS_ON_INITIALIZE) %}
        {{ type_declaration }},
      {% end %}
    )
      form = new(
        LuckyRecord::Params.new,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_CREATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}
      form.save!
    end

    def self.update(
        record,
        with params,
        {% for type_declaration in (NEEDS_ON_UPDATE + NEEDS_ON_INITIALIZE) %}
          {{ type_declaration }},
        {% end %}
      )
      form = new(
        record,
        params,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_UPDATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}
      if form.save
        yield form, form.record.not_nil!
      else
        yield form, form.record.not_nil!
      end
    end

    def self.update(
        record,
        {% for type_declaration in (NEEDS_ON_UPDATE + NEEDS_ON_INITIALIZE) %}
          {{ type_declaration }},
        {% end %}
      )
      form = new(
        record,
        LuckyRecord::Params.new,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_UPDATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}
      if form.save
        yield form, form.record.not_nil!
      else
        yield form, form.record.not_nil!
      end
    end

    def self.update!(
        record,
        {% for type_declaration in (NEEDS_ON_UPDATE + NEEDS_ON_INITIALIZE) %}
          {{ type_declaration }},
        {% end %}
      )
      form = new(
        record,
        LuckyRecord::Params.new,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_UPDATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}
      form.update!
    end

    def self.update!(
        record,
        with params,
        {% for type_declaration in (NEEDS_ON_UPDATE + NEEDS_ON_INITIALIZE) %}
          {{ type_declaration }},
        {% end %}
      )
      form = new(
        record,
        params,
        {% for type_declaration in NEEDS_ON_INITIALIZE %}
          {{ type_declaration.var }},
        {% end %}
      )
      {% for type_declaration in NEEDS_ON_UPDATE %}
        form.{{ type_declaration.var }} = {{ type_declaration.var }}
      {% end %}
      form.update!
    end
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
