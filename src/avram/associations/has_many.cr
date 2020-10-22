module Avram::Associations::HasMany
  macro has_many(type_declaration, through = nil, source = nil, foreign_key = nil)
    {% if !through.is_a?(NilLiteral) && !through.is_a?(SymbolLiteral) %}
      {% through.raise "The association name for 'through' must be a Symbol. Instead, got: #{through}" %}
    {% end %}
    {% if !source.is_a?(NilLiteral) && !source.is_a?(SymbolLiteral) %}
      {% source.raise "The value for 'source' must be a Symbol. Instead, got: #{source}" %}
    {% end %}
    {% if !source.is_a?(NilLiteral) && through.is_a?(NilLiteral) %}
      {% source.raise "Source must only be specified when defining a has many through relationship." %}
    {% end %}
    {% assoc_name = type_declaration.var %}

    {% unless foreign_key %}
      {% foreign_key = "#{@type.name.underscore.split("::").last.id}_id".id %}
    {% end %}

    {% foreign_key = foreign_key.id %}

    association \
      assoc_name: :{{ assoc_name }},
      type: {{ type_declaration.type }},
      foreign_key: :{{ foreign_key }},
      through: {{ through }},
      source: {{ source }},
      relationship_type: :has_many

    {% model = type_declaration.type %}

    define_has_many_lazy_loading({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ through }})
    define_has_many_base_query({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{through}})
  end

  private macro define_has_many_base_query(assoc_name, model, foreign_key, through)
    class BaseQuery < Avram::Query
      def preload_{{ assoc_name }}
        preload_{{ assoc_name }}({{ model }}::BaseQuery.new)
      end

      def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery)
        add_preload do |records|
          ids = records.map(&.id)
          if ids.empty?
            {{ assoc_name }} = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
          else
          {% if through %}
            all_{{ assoc_name }} = preload_query
              .dup
              .join_{{ through.id }}
              .__yield_where_{{ through.id }} do |through_query|
                through_query.{{ foreign_key.id }}.in(ids)
              end
              .preload_{{ through.id }}
              .distinct

            {{ assoc_name }} = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
            all_{{ assoc_name }}.each do |item|
              item.{{ through.id }}.each do |item_through|
                {{ assoc_name }}[item_through.{{ foreign_key }}] ||= Array({{ model }}).new
                {{ assoc_name }}[item_through.{{ foreign_key }}] << item
              end
            end
          {% else %}
            {{ assoc_name }} = preload_query
              .dup
              .{{ foreign_key }}.in(ids)
              .results.group_by(&.{{ foreign_key }})
          {% end %}
          end
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
      || raise Avram::LazyLoadError.new {{ @type.name.stringify }}, {{ assoc_name.stringify }}
    end

    def {{ assoc_name.id }}! : Array({{ model }})
      @_preloaded_{{ assoc_name }} || lazy_load_{{ assoc_name }}
    end

    def {{ assoc_name.id }}_count : Int64
      {% if through %}
        {{ model }}::BaseQuery
          .new
          .join_{{ through.id }}
          .__yield_where_{{ through.id }} do |through_query|
            through_query.{{ foreign_key.id }}(id)
          end
          .preload_{{ through.id }}
          .select_count
      {% else %}
        {{ model }}::BaseQuery
          .new
          .{{ foreign_key }}(id)
          .select_count
      {% end %}
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
          .__yield_where_{{ through.id }} do |through_query|
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
