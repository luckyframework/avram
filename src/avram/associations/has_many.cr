module Avram::Associations::HasMany
  macro has_many(type_declaration, through = nil, foreign_key = nil)
    {% if !through.is_a?(NilLiteral) && (!through.is_a?(ArrayLiteral) || through.any? { |item| !item.is_a?(SymbolLiteral) }) %}
      {% through.raise <<-ERROR
      'through' on #{@type.name} must be given an Array(Symbol). Instead, got: #{through}

      Example...
         has_many comments : Comment
         has_many related_authors : User, through: [:comments, :author]

      Learn more about associations: https://luckyframework.org/guides/database/models#model-associations
      ERROR
      %}
    {% end %}
    {% if !through.is_a?(NilLiteral) && through.size < 2 %}
      {% through.raise <<-ERROR
      'through' on #{@type.name} must be given at least two items. Instead, got: #{through}

      Example...
         has_many comments : Comment
         has_many related_authors : User, through: [:comments, :author]

      Learn more about associations: https://luckyframework.org/guides/database/models#model-associations
      ERROR
      %}
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
      relationship_type: :has_many

    {% model = type_declaration.type %}

    define_has_many_lazy_loading({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ through }})
    define_has_many_base_query({{ assoc_name }}, {{ model }}, {{ foreign_key }}, {{ through }})
  end

  private macro define_has_many_base_query(assoc_name, model, foreign_key, through)
    class BaseQuery
      def preload_{{ assoc_name }}
        preload_{{ assoc_name }}({{ model }}::BaseQuery.new)
      end

      def preload_{{ assoc_name }}
        modified_query = yield {{ model }}::BaseQuery.new
        preload_{{ assoc_name }}(modified_query)
      end

      {% if through %}
        def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery)
          preload_{{ through.first.id }} do |through_query|
            through_query.preload_{{ through[1].id }}(preload_query)
          end
          add_preload do |records|
            records.each do |record|
              throughs = record.{{ through.first.id }}
              throughs = throughs.is_a?(Array) ? throughs : [throughs]
              record._preloaded_{{ assoc_name }} = throughs.compact.flat_map do |through|
                throughs1 = through.{{ through[1].id }}
                throughs1.is_a?(Array) ? throughs1 : [throughs1]
              end.compact
            end
          end
          self
        end
      {% else %}
        def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery)
          add_preload do |records|
            ids = records.map(&.id)
            if ids.empty?
              {{ assoc_name }} = {} of {{ model }}::PrimaryKeyType => Array({{ model }})
            else
              {{ assoc_name }} = preload_query
                .{{ foreign_key }}.in(ids)
                .results.group_by(&.{{ foreign_key }})
            end
            records.each do |record|
              record._preloaded_{{ assoc_name }} = {{ assoc_name }}[record.id]? || [] of {{ model }}
            end
          end
          self
        end
      {% end %}
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
        {{ through.first.id }}_query
          .map(&.{{ through[1].id }}_count)
          .sum
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
        through_results = {{ through.first.id }}_query.preload_{{ through[1].id }}.results
        through_results = through_results.is_a?(Array) ? through_results : [through_results]
        through_results.compact.flat_map do |through_result|
          assoc_results = through_result.{{ through[1].id }}
          assoc_results.is_a?(Array) ? assoc_results : [assoc_results]
        end.compact
      {% else %}
        {{ model }}::BaseQuery
          .new
          .{{ foreign_key }}(id)
          .results
      {% end %}
    end
  end
end
