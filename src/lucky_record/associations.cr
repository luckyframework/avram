module LuckyRecord::Associations
  private def lazy_load_enabled?
    LuckyRecord::Repo.settings.lazy_load_enabled
  end

  macro has_many(type_declaration, through = nil, foreign_key = nil)
    {% if !through.is_a?(NilLiteral) && !through.is_a?(SymbolLiteral) %}
      {% through.raise "The association name for 'through' must be a Symbol. Instead, got: #{through}" %}
    {% end %}
    {% assoc_name = type_declaration.var %}

    {% unless foreign_key %}
      {% foreign_key = "#{@type.name.underscore}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}

    association table_name: :{{ assoc_name }},
      type: {{ type_declaration.type }},
      foreign_key: :{{ foreign_key }},
      through: {{ through }},
      relationship_type: :has_many

    {% model = type_declaration.type %}

    define_has_many_lazy_loading({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ through }})
  end

  macro has_one(type_declaration, foreign_key = nil)
    {% assoc_name = type_declaration.var %}

    {% if type_declaration.type.is_a?(Union) %}
      {% model = type_declaration.type.types.first %}
      {% nilable = true %}
    {% else %}
      {% model = type_declaration.type %}
      {% nilable = false %}
    {% end %}

    {% unless foreign_key %}
      {% foreign_key = "#{@type.name.underscore}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}

    association table_name: :{{ type_declaration.var }}, type: {{ model }}, foreign_key: {{ foreign_key }}, relationship_type: :has_one

    define_public_preloaded_getters({{ assoc_name }}, {{ model }}, {{ nilable }})
    define_preloaded_setter({{ assoc_name }}, {{ model }})
    define_has_one_private_assoc_getter({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ nilable }})
    define_has_one_base_query({{ assoc_name }}, {{ model }}, {{ foreign_key }})
  end

  macro belongs_to(type_declaration)
    {% assoc_name = type_declaration.var %}
    {% foreign_key = "#{assoc_name}_id".id %}

    {% if type_declaration.type.is_a?(Union) %}
      {% model = type_declaration.type.types.first %}
      {% nilable = true %}
    {% else %}
      {% model = type_declaration.type %}
      {% nilable = false %}
    {% end %}

    {% owner_id_type = model.resolve.constant(:PRIMARY_KEY_TYPE_CLASS) %}

    column {{ assoc_name.id }}_id : {{ owner_id_type }}{% if nilable %}?{% end %}

    association table_name: :{{ model.resolve.constant(:TABLE_NAME).id }},
                type: {{ model }},
                foreign_key: :{{ foreign_key }},
                relationship_type: :belongs_to

    define_belongs_to_private_assoc_getter({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ nilable }})
    define_public_preloaded_getters({{ assoc_name }}, {{ model }}, {{ nilable }})
    define_preloaded_setter({{ assoc_name }}, {{ model }})
    define_belongs_to_base_query({{ assoc_name }}, {{ model }}, {{ foreign_key }})
  end

  private macro define_public_preloaded_getters(assoc_name, model, nilable)
    def {{ assoc_name.id }}! : {{ model }}{% if nilable %}?{% end %}
      get_{{ assoc_name.id }}(allow_lazy: true)
    end

    def {{ assoc_name.id }} : {{ model }}{% if nilable %}?{% end %}
      get_{{ assoc_name.id }}
    end

    @_{{ assoc_name }}_preloaded : Bool = false
    getter? _{{ assoc_name }}_preloaded
    getter _preloaded_{{ assoc_name }} : {{ model }}?
  end

  private macro define_preloaded_setter(assoc_name, model)
    def set_preloaded_{{ assoc_name }}(record : {{ model }}?)
      @_{{ assoc_name }}_preloaded = true
      @_preloaded_{{ assoc_name }} = record
    end
  end

  private macro define_has_one_private_assoc_getter(assoc_name, model, foreign_key, nilable)
    private def get_{{ assoc_name.id }}(allow_lazy : Bool = false) : {{ model }}{% if nilable %}?{% end %}
      if _{{ assoc_name }}_preloaded?
        @_preloaded_{{ assoc_name }}{% unless nilable %}.not_nil!{% end %}
      elsif lazy_load_enabled? || allow_lazy
        query = {{ model }}::BaseQuery.new
        query.{{ foreign_key.id }}(id)

        query.first{% if nilable %}?{% end %}
      else
        raise LuckyRecord::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
      end
    end
  end

  private macro define_belongs_to_private_assoc_getter(assoc_name, model, foreign_key, nilable)
    private def get_{{ assoc_name.id }}(allow_lazy : Bool = false) : {{ model }}{% if nilable %}?{% end %}
      if _{{ assoc_name }}_preloaded?
        @_preloaded_{{ assoc_name }}{% unless nilable %}.not_nil!{% end %}
      elsif lazy_load_enabled? || allow_lazy
        {{ foreign_key }}.try do |value|
          {{ model }}::BaseQuery.new.find(value)
        end
      else
        raise LuckyRecord::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
      end
    end
  end

  private macro define_belongs_to_base_query(assoc_name, model, foreign_key)
    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}
        preload({{ model }}::BaseQuery.new)
      end

      def preload(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = [] of {{ model.resolve.constant(:PRIMARY_KEY_TYPE_CLASS) }}
          records.each do |record|
            record.{{ foreign_key }}.try do |id|
              ids << id
            end
          end
          {{ assoc_name }} = preload_query.id.in(ids).results.group_by(&.id)
          records.each do |record|
            if (id = record.{{ foreign_key }})
              record.set_preloaded_{{ assoc_name }} {{ assoc_name }}[id]?.try(&.first?)
            else
              record.set_preloaded_{{ assoc_name }} nil
            end
          end
        end
        self
      end
    end
  end

  private macro define_has_one_base_query(assoc_name, model, foreign_key)
    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}
        preload({{ model }}::BaseQuery.new)
      end

      def preload(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = records.map(&.id)
          {{ assoc_name }} = preload_query.{{ foreign_key }}.in(ids).results.group_by(&.{{ foreign_key }})
          records.each do |record|
            record.set_preloaded_{{ assoc_name }} {{ assoc_name }}[record.id]?.try(&.first?)
          end
        end
        self
      end
    end
  end

  private macro define_has_many_base_query(assoc_name, model, foreign_key, through)
    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}
        preload({{ model }}::BaseQuery.new)
      end

      def preload(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = records.map(&.id)
          {% if through %}
            all_{{ assoc_name }} = preload_query
              .join_{{ through.id }}
              .{{ through.id }} do |through_query|
                through_query.{{ foreign_key.id }}.in(ids)
              end
              .preload_{{ through.id }}
              .distinct

            {% owner_id_type = model.resolve.constant(:PRIMARY_KEY_TYPE_CLASS) %}

            {{ assoc_name }} = {} of {{ owner_id_type }} => Array({{ model }})
            all_{{ assoc_name }}.each do |item|
              item.{{ through.id }}.each do |item_through|
                {{ assoc_name }}[item_through.{{ foreign_key }}] ||= Array({{ model }}).new
                {{ assoc_name }}[item_through.{{ foreign_key }}] << item
              end
            end
          {% else %}
            {{ assoc_name }} = preload_query
              .{{ foreign_key }}.in(ids)
              .results.group_by(&.{{ foreign_key }})
          {% end %}
          records.each do |record|
            record._preloaded_{{ assoc_name }} = {{ assoc_name }}[record.id]? || [] of {{ model }}
          end
        end
        self
      end
    end
  end

  private macro define_has_many_lazy_loading(assoc_name, model, foreign_key, through)
    @_preloaded_{{ assoc_name }} : Array({{ model }})?
    setter _preloaded_{{ assoc_name }}

    def {{ assoc_name.id }} : Array({{ model }})
      @_preloaded_{{ assoc_name }} \
      || maybe_lazy_load_{{ assoc_name }} \
      || raise LuckyRecord::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
    end

    def {{ assoc_name.id }}! : Array({{ model }})
      @_preloaded_{{ assoc_name }} || lazy_load_{{ assoc_name }}
    end

    private def maybe_lazy_load_{{ assoc_name }}  : Array({{ model }})?
      if lazy_load_enabled?
        lazy_load_{{ assoc_name }}
      end
    end

    private def lazy_load_{{ assoc_name }} : Array({{ model }})
      {% if through %}
        {{ model }}::BaseQuery
          .new
          .join_{{ through.id }}
          .{{ through.id }} do |through_query|
            through_query.{{ foreign_key.id }}(id)
          end
          .preload_{{ through.id }}
          .results
      {% else %}
        {{ model }}::BaseQuery
          .new
          .{{ foreign_key }}(id)
          .results
      {% end %}
    end
  end
end
