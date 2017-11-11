module LuckyRecord::NeedyInitializer
  macro included
    NEEDS = [] of Nil

    macro inherited
      inherit_page_settings
    end

    generate_initializer
  end

  macro needs(type_declaration)
    {% NEEDS << type_declaration %}
  end

  macro inherit_page_settings
    NEEDS = [] of Nil

    \{% if !@type.ancestors.first.abstract? %}
      \{% for type_declaration in @type.ancestors.first.constant :NEEDS %}
        \{% NEEDS << type_declaration %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_page_settings
    end

    macro finished
      generate_initializer
      generate_getters
      generate_save_methods
    end
  end

  macro generate_save_methods
    def self.save(
        params,
        {% if NEEDS.size > 0 %}
          **needs
        {% end %}
      )
      form = new(
        params,
        {% if NEEDS.size > 0 %}
          **needs
        {% end %}
      )
      if form.save
        yield form, form.record
      else
        yield form, nil
      end
    end

    def self.save!(
        params,
        {% if NEEDS.size > 0 %}
          **needs
        {% end %}
      )
      form = new(
        params,
        {% if NEEDS.size > 0 %}
          **needs
        {% end %}
      ).save!
    end

    def self.update(
        record,
        with params,
        {% if NEEDS.size > 0 %}
          **needs
        {% end %}
      )
      form = new(
        record,
        params,
        {% if NEEDS.size > 0 %}
          **needs
        {% end %}
      )
      if form.save
        yield form, form.record.not_nil!
      else
        yield form, form.record.not_nil!
      end
    end

    def self.update!(
        record,
        with params,
        {% if NEEDS.size > 0 %}
          **needs
        {% end %}
      )
      form = new(
        record,
        params,
        {% if NEEDS.size > 0 %}
          **needs
        {% end %}
      ).update!
    end
  end

  macro generate_getters
    {% for need in NEEDS %}
      getter {{ need.var }}
    {% end %}
  end

  macro generate_initializer
    def initialize(
        params : Hash(String, String) | LuckyRecord::Paramable,
        {% for type_declaration in NEEDS %}
          @{{ type_declaration }},
        {% end %}
      )
      @params = ensure_paramable(params)
      extract_changes_from_params
    end

    def initialize(
        {% for type_declaration in NEEDS %}
          @{{ type_declaration }},
        {% end %}
        **params
      )
      @params = named_tuple_to_params(params)
      extract_changes_from_params
    end

    def initialize(
        @record,
        params : Hash(String, String) | LuckyRecord::Paramable,
        {% for type_declaration in NEEDS %}
          @{{ type_declaration }},
        {% end %}
      )
      @params = ensure_paramable(params)
      extract_changes_from_params
    end

    def initialize(
        @record,
        {% for type_declaration in NEEDS %}
          @{{ type_declaration }},
        {% end %}
        **params
      )
      @params = named_tuple_to_params(params)
      extract_changes_from_params
    end
  end
end
